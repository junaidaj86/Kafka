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

## Conclusion

You have successfully set up a Kafka cluster on a Kind cluster using the Strimzi operator. You can now create topics, produce and consume messages as needed.

For further customization and details, refer to the [Strimzi Documentation](https://strimzi.io/docs/).

