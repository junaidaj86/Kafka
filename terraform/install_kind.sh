#!/bin/bash

# Install Docker if not already installed
if ! command -v docker &> /dev/null
then
    echo "Docker not found, installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
fi

# Install Kind if not already installed
if ! command -v kind &> /dev/null
then
    echo "Kind not found, installing Kind..."
    curl -Lo ./kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64
    chmod +x ./kind
    sudo mv ./kind /usr/local/bin/kind
fi

# Install kubectl if not already installed
if ! command -v kubectl &> /dev/null
then
    echo "kubectl not found, installing kubectl..."
    curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x ./kubectl
    sudo mv ./kubectl /usr/local/bin/kubectl
fi

# Install Helm if not already installed
if ! command -v helm &> /dev/null
then
    echo "Helm not found, installing Helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# Create Kind cluster
kind create cluster --config kind-cluster.yaml

# Verify that the Kind cluster is running
kubectl cluster-info
