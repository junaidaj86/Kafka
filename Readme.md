# Kafka Cluster Deployment using Strimzi Operator with MetalLB and Custom Kafka Connect Image

This guide will help you set up a Kafka cluster on a Kubernetes environment using the Strimzi Kafka Operator, configured with MetalLB for load balancing. Additionally, we will build a custom Kafka Connect image that includes the Confluent JDBC connector.

## Prerequisites

Ensure the following tools are installed on your system:
- [Docker](https://docs.docker.com/get-docker/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [Helm](https://helm.sh/docs/intro/install/)
- [Kind](https://kind.sigs.k8s.io/)

## Step 1: Create a Kind Cluster

Create a Kubernetes cluster using Kind with one control plane and one worker node.

```yaml
# kind-cluster-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
  - role: worker
```

Run the command to create the cluster:

```bash
kind create cluster --config kind-cluster.yaml
```

## Step 2: Install MetalLB

Install MetalLB for load balancing in your Kubernetes cluster:

```bash
helm repo add metallb https://metallb.github.io/metallb
helm install metallb metallb/metallb

kubectl apply -f - << EOF
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: demo-pool
  namespace: default
spec:
  addresses:
  - 172.18.0.100-172.18.0.140
EOF

kubectl apply -f - << EOF
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: example
  namespace: default
spec:
  ipAddressPools:
  - demo-pool
EOF
```

## Step 3: Install Strimzi Kafka Operator

Create a script `install-strimzi.sh` for automating the Strimzi installation:

```bash
#!/bin/bash

# Variables
NAMESPACE="strimzi"
HELM_REPO_NAME="strimzi"
HELM_REPO_URL="https://strimzi.io/charts/"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for required commands
if ! command_exists kubectl; then
    echo "kubectl is not installed. Please install it first."
    exit 1
fi

if ! command_exists helm; then
    echo "Helm is not installed. Please install it first."
    exit 1
fi

# Create the Strimzi namespace if it doesn't exist
kubectl get namespace "$NAMESPACE" >/dev/null 2>&1 || {
    echo "Creating namespace '$NAMESPACE'..."
    kubectl create namespace "$NAMESPACE"
}

# Add the Strimzi Helm repository
echo "Adding Strimzi Helm repository..."
helm repo add "$HELM_REPO_NAME" "$HELM_REPO_URL"

# Update Helm repositories
echo "Updating Helm repositories..."
helm repo update

# Install the Strimzi Kafka Operator
echo "Installing Strimzi Kafka Operator..."
helm install strimzi-kafka-operator "$HELM_REPO_NAME"/strimzi-kafka-operator --namespace "$NAMESPACE"

# Wait for the operator to be ready
echo "Waiting for Strimzi Kafka Operator to be ready..."
kubectl wait --for=condition=available --timeout=600s deployment/strimzi-cluster-operator -n "$NAMESPACE"

# Verify the installation
echo "Strimzi Kafka Operator installation completed. Verifying installation..."
kubectl get pods -n "$NAMESPACE"

echo "Installation complete!"
```

Run the script:

```bash
chmod +x install-strimzi.sh
./install-strimzi.sh
```

## Step 4: Deploy Kafka Cluster

Create a `kafka-cluster.yaml` file with the configuration:

```yaml
apiVersion: kafka.strimzi.io/v1beta2
kind: Kafka
metadata:
  name: my-kafka-cluster
  namespace: kafka
spec:
  kafka:
    replicas: 3
    listeners:
      - name: plain
        port: 9092
        type: internal
        tls: false
      - name: external
        port: 9094
        type: loadbalancer
        tls: false
    config:
      "offsets.topic.replication.factor": 3
      "transaction.state.log.replication.factor": 3
      "transaction.state.log.min.isr": 2
      "log.message.format.version": "2.8"
    storage:
      type: ephemeral
  zookeeper:
    replicas: 3
    storage:
      type: ephemeral
  entityOperator:
    topicOperator: {}
    userOperator: {}
```

Apply the configuration:

```bash
kubectl apply -f kafka-cluster.yaml
```

## Step 5: Build and Push Custom Kafka Connect Image

Create a `Dockerfile` for Kafka Connect:

```Dockerfile
FROM quay.io/strimzi/kafka:0.43.0-kafka-3.7.0
USER root
# Add additional plugins or configurations here
ADD confluentinc-kafka-connect-jdbc-10.8.0 /opt/kafka/plugins/confluentinc-kafka-connect-jdbc-10.8.0
USER 1001
```

Build and tag the image:

```bash
docker build --platform=linux/amd64 -t junaidajdocker/junaid-confluentinc-kafka-connect-jdbc-10.8.0:latest .
```

Push the image to a Docker registry:

```bash
docker push junaidajdocker/junaid-confluentinc-kafka-connect-jdbc-10.8.0:latest
```

## Step 6: Deploy Kafka Connect

Create a `kafka-connect.yaml` file:

```yaml
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaConnect
metadata:
  name: kafka-connect
  namespace: kafka
  annotations:
    strimzi.io/use-connector-resources: "true"
spec:
  bootstrapServers: my-kafka-cluster-kafka-bootstrap:9092
  version: 3.7.0
  replicas: 1
  image: junaidajdocker/junaid-confluentinc-kafka-connect-jdbc-10.8.0:latest
  config:
    group.id: my-connect-cluster
    offset.storage.topic: my-connect-cluster-offsets
    config.storage.topic: my-connect-cluster-configs
    status.storage.topic: my-connect-cluster-status
    key.converter: org.apache.kafka.connect.storage.StringConverter
    value.converter: org.apache.kafka.connect.storage.StringConverter
    key.converter.schemas.enable: true
    value.converter.schemas.enable: true
    config.storage.replication.factor: 3
    offset.storage.replication.factor: 3
    status.storage.replication.factor: 3
    plugin.path: /opt/kafka/plugins
```

Apply the configuration:

```bash
kubectl apply -f kafka-connect.yaml
```

## Step 7: Deploy Kafka Connector

Create a `kafka-connector.yaml` file:

```yaml
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaConnector
metadata:
  name: postgres-source-connector-1
  namespace: kafka
  labels:
    strimzi.io/cluster: kafka-connect
spec:
  class: io.confluent.connect.jdbc.JdbcSourceConnector
  tasksMax: 3
  config:
    connector.class: io.confluent.connect.jdbc.JdbcSourceConnector
    tasks.max: "3"
    topics: "users"
    connection.url: "jdbc:postgresql://postgres:5432/exampledb"
    connection.user: "postgres"
    connection.password: "examplepassword"
    table.whitelist: "users"
    mode: "incrementing"
    incrementing.column.name: "id"
    poll.interval.ms: "5000"
    timestamp.column.name: "last_modified"
    numeric.mapping: "best_fit"
    value.converter: org.apache.kafka.connect.json.JsonConverter
    value.converter.schemas.enable: "false"
```

Apply the configuration:

```bash
kubectl apply -f kafka-connector.yaml
```

## Conclusion

You have successfully set up a Kafka cluster using Strimzi Operator, integrated with MetalLB for load balancing, and deployed a custom Kafka Connect image. You also created a Kafka Connector for sourcing data from PostgreSQL.
```

# Create a secret for the broker certificate
kubectl create secret generic broker-secret --from-file=/Users/jja8go/certs/broker/broker.crt

# Create a secret for the CA certificate
kubectl create secret generic ca-secret --from-file=/Users/jja8go/certs/ca/certs/ca.crt
