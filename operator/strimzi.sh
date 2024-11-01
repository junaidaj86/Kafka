#!/bin/bash

# Script to install Strimzi Kafka Operator on Kubernetes

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
