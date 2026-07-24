#!/bin/bash

# Create the kind cluster
kind create cluster --config .infrastructure/cluster.yml

# Create namespace
kubectl apply -f .infrastructure/namespace.yml

# Init Secrets
kubectl apply -f .infrastructure/secrets.yml

# Init Config map
kubectl apply -f .infrastructure/configMap.yml

# Init Services
kubectl apply -f .infrastructure/clusterip.yml
kubectl apply -f .infrastructure/nodeport.yml

# PV and PVC
kubectl apply -f .infrastructure/pv.yml
kubectl apply -f .infrastructure/pvc.yml

# Deploy MySQL StatefulSet
kubectl apply -f .infrastructure/statefulSet.yml

# Deployment
kubectl apply -f .infrastructure/deployment.yml

# hpa
kubectl apply -f .infrastructure/hpa.yml