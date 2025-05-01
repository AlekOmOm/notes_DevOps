# 1a. From Docker to Your First Pod - Detailed Guide 🐳

[<- Back: Main Topic](./01-docker-to-pod.md) | [Next Sub-Topic: Basic Orchestration & Scaling ->](./02-orchestration-scaling.md)

## Overview

This detailed sub-note provides hands-on instructions for the most basic Kubernetes workflow: setting up a local environment, deploying your first containerized application, and accessing it from your machine. This guide bridges the gap between running individual Docker containers and orchestrating them with Kubernetes.

## Key Concepts

### From Docker to Kubernetes

Docker helps you package applications into containers, but managing multiple containers at scale requires orchestration. Kubernetes provides this orchestration layer, handling deployment, scaling, and management of containerized applications.

```
Docker Run                 Kubernetes
+-------------+            +------------------------+
| docker run  |  evolves   | kubectl create         |
| nginx       |  ------->  | deployment nginx       |
+-------------+            +------------------------+
```

### Core Tools

- **kubectl**: The command-line interface for any Kubernetes cluster
- **Minikube**: A tool that creates a single-node Kubernetes cluster locally for development and learning

## Implementation Steps

### 1. Installation

Before you can start working with Kubernetes, you need to install the necessary tools:

#### Installing kubectl

Follow the official documentation for your operating system:

**macOS (using Homebrew):**
```bash
brew install kubectl
```

**Windows (using Chocolatey):**
```bash
choco install kubernetes-cli
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt update
sudo apt install -y kubectl
```

#### Installing Minikube

Follow the official Minikube documentation:

**macOS (using Homebrew):**
```bash
brew install minikube
```

**Windows (using Chocolatey):**
```bash
choco install minikube
```

**Linux (download binary):**
```bash
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
```

#### Verify Installation

Open a new terminal window and run:
```bash
kubectl version --client
minikube version
```

You should see version information for both tools.

### 2. Starting Your Local Kubernetes Cluster

Minikube needs a "driver" to create the cluster environment. Since you already have Docker, we'll use that:

```bash
minikube start --driver=docker
```

This might take a few minutes the first time as it downloads necessary images. It will also automatically configure `kubectl` to talk to this new Minikube cluster.

Check the cluster status:
```bash
minikube status
```

You should see output indicating the `host`, `kubelet`, and `apiserver` are all `Running`.

### 3. Interacting with Your Cluster

Now that your cluster is running, let's explore it using `kubectl`:

#### Get Cluster Information

```bash
kubectl cluster-info
```

This shows basic information about the control plane and services.

#### List Nodes

```bash
kubectl get nodes
```

You'll see one node named `minikube`, its status (`Ready`), role (`control-plane,master`), and age.

#### Check Initial Pods

```bash
kubectl get pods
```

You should see "No resources found in default namespace." There are system pods running in other namespaces like `kube-system`, but we'll focus on the default namespace for now.

### 4. Running Your First Application

We'll deploy the standard Nginx web server image from Docker Hub:

#### Create a Deployment

```bash
kubectl create deployment my-nginx --image=nginx
```

A Deployment tells Kubernetes how to create and update instances of your application. This command tells Kubernetes to run one container using the Nginx image.

Check the deployment:
```bash
kubectl get deployments
```

You should see `my-nginx` listed, likely showing `1/1` under `READY`.

#### Check the Pod

```bash
kubectl get pods
```

You'll see a pod named something like `my-nginx-xxxxxxxxxx-yyyyy`. Its `STATUS` should become `Running`. Kubernetes ensures this pod stays running.

#### Expose the Deployment

Right now, Nginx is running inside the cluster, but you can't access it from your browser. We need to expose it using a Service:

```bash
kubectl expose deployment my-nginx --type=NodePort --port=80
```

This creates a Service that makes your deployment accessible outside the cluster. The `NodePort` type exposes the Service on a port on each Node in the cluster.

#### Find the Access URL

```bash
minikube service my-nginx --url
```

This outputs a URL like `http://192.168.49.2:3XXXX`. The IP address and port number will vary.

#### Access Your Application

Copy the URL and paste it into your browser. You should see the "Welcome to nginx!" page. Congratulations, you've deployed and accessed your first application on Kubernetes!

### 5. Clean Up

It's good practice to remove resources when you're done:

Delete the Service:
```bash
kubectl delete service my-nginx
```

Delete the Deployment (this will also delete the Pod it manages):
```bash
kubectl delete deployment my-nginx
```

Verify they're gone:
```bash
kubectl get services
kubectl get deployments
```

Alternatively, you can quickly delete all resources in the current namespace:
```bash
kubectl delete all --all
```

## Common Challenges and Solutions

### Challenge 1: Minikube Won't Start

**Problem:** `minikube start` fails with driver-related errors.

**Solution:**

```bash
# Make sure Docker is running
docker ps

# Try with a different driver if Docker isn't available
minikube start --driver=virtualbox

# Or check status and delete problematic cluster
minikube status
minikube delete
minikube start --driver=docker
```

### Challenge 2: Can't Access the Application

**Problem:** The URL from `minikube service` doesn't work.

**Solution:**

```bash
# Check if the service exists
kubectl get services

# Check pod status to ensure it's running
kubectl get pods

# Try using port-forward as an alternative
POD_NAME=$(kubectl get pods -l app=my-nginx -o jsonpath='{.items[0].metadata.name}')
kubectl port-forward $POD_NAME 8080:80
# Then access http://localhost:8080 in your browser
```

## Practical Example

This example shows the complete workflow from start to finish:

```bash
# Start Minikube
minikube start --driver=docker

# Create a deployment
kubectl create deployment hello-web --image=nginx

# Wait for pod to be ready
kubectl wait --for=condition=ready pod -l app=hello-web

# Expose the application
kubectl expose deployment hello-web --type=NodePort --port=80

# Get the URL
minikube service hello-web --url

# (Open the URL in your browser)

# Clean up
kubectl delete service hello-web
kubectl delete deployment hello-web
```

## Summary

You've successfully:
1. Set up a local Kubernetes environment using Minikube
2. Learned basic kubectl commands to interact with your cluster
3. Deployed an application (Nginx) to Kubernetes using a Deployment
4. Exposed your application using a Service
5. Accessed your application through the browser

You've made the crucial transition from thinking in terms of individual containers to Kubernetes objects like Deployments, Pods, and Services. This provides the foundation for the more advanced concepts in the next stages.

## Next Steps

Now that you've deployed a single instance of an application, it's time to explore multi-instance deployment, scaling, and the declarative approach to Kubernetes configuration.

---

[<- Back: Main Topic](./01-docker-to-pod.md) | [Next Sub-Topic: Basic Orchestration & Scaling ->](./02-orchestration-scaling.md)
