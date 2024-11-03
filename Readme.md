# Setting Up a Kafka Cluster on Kind

This document provides step-by-step instructions for installing a Kafka cluster on a Kind (Kubernetes IN Docker) cluster using the Strimzi operator.

## Prerequisites

1. **Docker**: Make sure Docker is installed and running on your machine.
2. **Kind**: Install Kind using Homebrew:
   ```bash
   brew install kind
   ```

## Create a Kind Cluster

1. **Create a Kind Configuration File**:
   Create a file named `kind-config.yaml` with your desired configuration.

2. **Create the Kind Cluster**:
   Run the following command to create a Kind cluster named `kafka`:
   ```bash
   kind create cluster --name kafka --config kind-config.yaml
   ```

## Kubernetes Context Management

### Check Current Context
To see the current Kubernetes context:
```bash
kubectl config current-context
```

### Get All Contexts
To list all available contexts:
```bash
kubectl config get-contexts
```

### Switch Context
To switch to a specific context (e.g., `kind-kafka`):
```bash
kubectl config use-context <context-name>
```
Example:
```bash
kubectl config use-context kind-kafka
```

## Deploying Kafka on the Kubernetes Cluster

1. **Create a Namespace for Kafka**:
   ```bash
   kubectl create namespace kafka
   ```

2. **Deploy the Strimzi Operator**:
   Use the following command to deploy the Strimzi operator:
   ```bash
   kubectl apply -f "https://strimzi.io/install/latest?namespace=kafka" -n kafka
   ```

3. **Check if the Strimzi Operator is Ready**:
   Verify the deployment of the Strimzi operator:
   ```bash
   kubectl get pods -n kafka
   ```

## Install Kafka

1. **Deploy the Kafka Cluster**:
   Create a Kafka cluster using a configuration file (e.g., `kafka-cluster.yaml`):
   ```bash
   kubectl apply -f kafka-cluster.yaml -n kafka
   ```

2. **Check Kafka Deployment**:
   Verify that all Kafka pods are running successfully:
   ```bash
   kubectl get pods -n kafka
   ```

## Connect to Kafka

To use the Kafka command-line tools from your local machine, you'll need to port-forward the Kafka bootstrap service:

1. **Port Forwarding**:
   Run the following command in a new terminal window (do not close this terminal to maintain the connection):
   ```bash
   kubectl port-forward service/my-kafka-cluster-kafka-bootstrap 9092:9092 -n kafka
   ```

## Sanity Test: Create and List Topics

### Create a Topic
1. **Apply Topic Configuration**:
   Use a configuration file (e.g., `topic.yaml`) to create a topic:
   ```bash
   kubectl apply -f topic.yaml -n kafka
   ```

### Verify Kafka Brokers
1. **Get Kafka Broker Pods**:
   Find the broker pods:
   ```bash
   kubectl get pods -n kafka
   ```

2. **Log into a Broker Pod**:
   Access the first Kafka broker pod:
   ```bash
   kubectl exec -it my-kafka-cluster-kafka-0 -n kafka -- /bin/bash
   ```

3. **Locate Kafka Scripts**:
   Find the Kafka scripts in the container:
   ```bash
   find / -name kafka-topics.sh 2>/dev/null
   ```

   Example output:
   ```
   /opt/kafka/bin/kafka-topics.sh
   ```

4. **List Topics**:
   Use the found path to list the topics:
   ```bash
   /opt/kafka/bin/kafka-topics.sh --list --bootstrap-server localhost:9092
   ```

## Monitoring

kubectl create namespace monitoring

### install prometheus operator
brew install helm

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install my-prometheus prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace


## Conclusion

You have successfully set up a Kafka cluster on a Kind cluster using the Strimzi operator. You can now create topics, produce and consume messages as needed.

For further customization and details, refer to the [Strimzi Documentation](https://strimzi.io/docs/).



## Metallb for load balancer in local env https://www.youtube.com/watch?v=43fn499NYXs

#### steps
Here is a step-by-step guide in Markdown format:

```markdown
# Step-by-Step Guide for Setting up MetalLB with Helm and Configuring IP Address Pool and L2 Advertisement

This guide covers the setup of MetalLB on a Kubernetes cluster, using Helm for installation, followed by IP pool configuration for load balancing with Layer 2 advertisement.

---

## Step 1: Add the MetalLB Helm Repository

First, add the official MetalLB Helm repository to your local Helm configuration.

```bash
helm repo add metallb https://metallb.github.io/metallb
```

## Step 2: Install MetalLB Using Helm

Now that the MetalLB repository is added, install MetalLB in your Kubernetes cluster.

```bash
helm install metallb metallb/metallb
```

This command installs MetalLB in the default namespace (`metallb-system`), creating all required resources.

## Step 3: Verify the Docker Network for Kind

If you're running Kubernetes in a Kind (Kubernetes in Docker) cluster, inspect the Docker network to ensure you’re using the correct IP range. 

```bash
docker network inspect kind
```

Note down the IP address range used in this network for use in the IP pool configuration.

## Step 4: Configure an IP Address Pool for MetalLB

Apply an `IPAddressPool` resource to define a range of IP addresses for MetalLB. Replace the IP range below with a suitable range from your network.

```bash
kubectl apply -f - << EOF
apiVersion: metallb.io/v1beta1
kind: IPAddressPool  
metadata:
  name: demo-pool
  namespace: default
spec:
  addresses:     
  - 172.19.0.10-172.19.0.30
EOF
```

This command creates an IP pool named `demo-pool` in the `default` namespace, with addresses in the specified range.

## Step 5: Configure L2 Advertisement for MetalLB

Next, apply an `L2Advertisement` resource to enable Layer 2 mode for load balancing, associating it with the previously created IP address pool.

```bash
kubectl apply -f - << EOF
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: demo
  namespace: default
spec:
  ipAddressPools:
  - demo-pool
EOF
```

This step configures MetalLB to advertise IPs in `demo-pool` using Layer 2 mode, enabling the load balancer to respond to ARP requests on the local network.

---

Your MetalLB configuration should now be complete, allowing Kubernetes services of type `LoadBalancer` to allocate IPs from `demo-pool`.
```