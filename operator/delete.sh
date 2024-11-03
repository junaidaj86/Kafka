#!/bin/bash

# Namespace where Strimzi and Kafka resources are deployed
NAMESPACE="strimzi"

echo "Deleting all Kafka and Strimzi resources in the '$NAMESPACE' namespace..."

# Step 1: Delete all resources in the Strimzi namespace
kubectl delete all --all -n "$NAMESPACE"

# Step 2: Delete the Strimzi namespace (optional, only if you don’t need it)
kubectl delete namespace "$NAMESPACE"

# Step 3: Stop and delete the KinD cluster
echo "Deleting KinD cluster..."

# This will delete the KinD cluster entirely, including all resources within it
kind delete cluster

echo "Deletion complete. All Strimzi and KinD cluster resources have been removed."
