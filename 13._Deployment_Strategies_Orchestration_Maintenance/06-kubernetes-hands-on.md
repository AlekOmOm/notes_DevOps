# 6. Kubernetes Hands-On 🔧

[<- Back: Kubernetes](./05-kubernetes.md) | [Next: System Resilience ->](./07-resilience.md)

## Table of Contents

- [Introduction](#introduction)
- [Setting Up Kubernetes Locally](#setting-up-kubernetes-locally)
- [Basic Kubernetes Operations](#basic-kubernetes-operations)
- [Creating and Managing Deployments](#creating-and-managing-deployments)
- [Exposing Services](#exposing-services)
- [Declarative Configuration](#declarative-configuration)
- [Introduction to Helm](#introduction-to-helm)
- [Summary](#summary)

## Introduction

This section provides a hands-on introduction to working with Kubernetes through Minikube, a tool that creates a single-node Kubernetes cluster on your local machine. By working through these practical examples, you'll gain experience with the fundamental operations needed to deploy and manage applications in Kubernetes.

## Setting Up Kubernetes Locally

To work with Kubernetes locally, you'll need two primary tools:

1. **kubectl**: The Kubernetes command-line tool for interacting with clusters
2. **Minikube**: A tool that runs a single-node Kubernetes cluster on your machine

### Installing kubectl and Minikube

#### macOS

Using Homebrew:

```bash
brew install kubectl minikube
```

#### Windows

Using Chocolatey:

```powershell
choco install kubernetes-cli minikube
```

### Starting Minikube

Minikube requires a driver to create and manage the local Kubernetes virtual machine:

```bash
minikube start --driver=docker
```

The `--driver` flag specifies which virtualization technology to use. Common options include:
- Docker
- Hyperkit
- KVM2
- Parallels
- VirtualBox
- VMware Fusion/Workstation

> **Note**: When using the Docker driver, there are limitations for certain features like ingress outside of Linux environments.

### Checking Minikube Status

Verify that Minikube is running:

```bash
minikube status
```

You should see output indicating that the Minikube host, kubelet, and API server are all running.

### Stopping Minikube

When you're done, you can stop Minikube:

```bash
minikube stop
```

### Accessing the Minikube VM

You can SSH into the Minikube VM to inspect its configuration:

```bash
minikube ssh
```

Once connected, you can explore the container runtime:

```bash
docker ps
```

This will show the containers running within the Minikube VM, including the Kubernetes components.

## Basic Kubernetes Operations

Now that Minikube is running, let's explore basic operations using `kubectl`.

### Exploring the Cluster

Check the cluster information:

```bash
kubectl cluster-info
```

List the nodes in the cluster (in Minikube, there's only one):

```bash
kubectl get nodes
```

Check the services running in the default namespace:

```bash
kubectl get services
```

### Working with Namespaces

Namespaces provide a way to divide cluster resources. Let's explore them:

```bash
kubectl get namespaces
```

The default namespaces are:
- `default`: For user-created resources without a specified namespace
- `kube-system`: For Kubernetes system components
- `kube-public`: For publicly accessible resources
- `kube-node-lease`: For node heartbeats

View resources in a specific namespace:

```bash
kubectl get pods -n kube-system
```

This shows the system pods that run Kubernetes components.

## Creating and Managing Deployments

Let's create applications in Kubernetes, starting with the most basic approach.

### Imperative Pod Creation

The simplest way to run a container in Kubernetes is to create a pod directly:

```bash
kubectl run nginx --image=nginx
```

Verify the pod is running:

```bash
kubectl get pods
```

View detailed information about the pod:

```bash
kubectl describe pod nginx
```

Delete the pod when you're done:

```bash
kubectl delete pod nginx
```

### Creating a Deployment

While you could create individual pods, Deployments provide better management capabilities:

```bash
kubectl create deployment nginx --image=nginx
```

List deployments:

```bash
kubectl get deployments
```

The deployment automatically creates a ReplicaSet and pods:

```bash
kubectl get pods
```

## Exposing Services

Pods running in Kubernetes are not accessible from outside the cluster by default. We need to expose them using Services.

### Service Types

Kubernetes supports several service types:

1. **ClusterIP**: Internal-only IP accessible within the cluster
2. **NodePort**: Exposes the service on each node's IP at a specific port
3. **LoadBalancer**: Uses a cloud provider's load balancer to expose the service
4. **ExternalName**: Maps the service to a DNS name

### Creating a Service

Let's expose our nginx deployment as a NodePort service:

```bash
kubectl expose deployment nginx --port=80 --type=NodePort
```

List the services:

```bash
kubectl get services
```

### Accessing the Service

In Minikube, you can get the URL to access a service:

```bash
minikube service nginx --url
```

This returns a URL with the Minikube IP and assigned NodePort, which you can open in a browser.

To open the service directly from the command line:

```bash
minikube service nginx
```

### Cleaning Up

Delete the service:

```bash
kubectl delete service nginx
```

## Creating and Exposing a Custom Application

Let's try with a custom application:

```bash
kubectl create deployment k8s-web-hello --image=andlocker/k8s-web-hello
kubectl expose deployment k8s-web-hello --port=3000 --type=NodePort
```

Access the application:

```bash
minikube service k8s-web-hello
```

### Manual Scaling

Scale the deployment to run multiple replicas:

```bash
kubectl scale deployment k8s-web-hello --replicas=4
```

Verify the replicas:

```bash
kubectl get pods
```

You should see four pods running your application.

### Cleaning Up Everything

To remove all resources:

```bash
kubectl delete all --all
```

This deletes all resources in the default namespace, giving you a clean slate.

## Declarative Configuration

While the imperative commands we've used so far are convenient for quick tasks, Kubernetes is designed for declarative configuration using YAML files.

### Creating a Deployment YAML

Create a file named `deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: k8s-web-hello
spec:
  selector:
    matchLabels:
      app: k8s-web-hello
  template:
    metadata:
      labels:
        app: k8s-web-hello
    spec:
      containers:
      - name: k8s-web-hello
        image: andlocker/k8s-web-hello:latest
        resources:
          limits:
            memory: "128Mi"
            cpu: "500m"
        ports:
        - containerPort: 3000
```

Apply the configuration:

```bash
kubectl apply -f deployment.yaml
```

### Scaling with YAML

To scale the deployment, modify the `deployment.yaml` file to include replicas:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: k8s-web-hello
spec:
  replicas: 4  # Add this line
  selector:
    matchLabels:
      app: k8s-web-hello
  # Rest of the file remains the same
```

Apply the updated configuration:

```bash
kubectl apply -f deployment.yaml
```

### Creating a Service YAML

Create a file named `service.yaml` for our service:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: hello
spec:
  type: LoadBalancer
  selector:
    app: k8s-web-hello
  ports:
  - port: 3000
    targetPort: 3000
```

Apply the service configuration:

```bash
kubectl apply -f service.yaml
```

Access the service:

```bash
minikube service hello
```

### Combining Deployment and Service

A common practice is to combine multiple resource definitions in a single file:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: k8s-web-hello
spec:
  replicas: 4
  selector:
    matchLabels:
      app: k8s-web-hello
  template:
    metadata:
      labels:
        app: k8s-web-hello
    spec:
      containers:
      - name: k8s-web-hello
        image: andlocker/k8s-web-hello:latest
        resources:
          limits:
            memory: "128Mi"
            cpu: "500m"
        ports:
        - containerPort: 3000
---
apiVersion: v1
kind: Service
metadata:
  name: k8s-web-hello
spec:
  type: LoadBalancer
  selector:
    app: k8s-web-hello
  ports:
  - port: 3000
    targetPort: 3000
```

Save this as `deployment_service.yaml` and apply it:

```bash
kubectl apply -f deployment_service.yaml
```

Access the service:

```bash
minikube service k8s-web-hello
```

Clean up:

```bash
kubectl delete -f deployment_service.yaml
```

## Introduction to Helm

Helm is a package manager for Kubernetes that simplifies the deployment and management of applications.

### What Helm Provides

- **Helm Charts**: Packaged applications for Kubernetes
- **Templating Engine**: Generate Kubernetes manifests dynamically
- **Release Management**: Track and manage deployment versions

### Installing Helm

#### macOS

```bash
brew install helm
```

#### Windows

```powershell
choco install kubernetes-helm
```

### Using Helm

Install a package using Helm:

```bash
helm install my-nginx bitnami/nginx
```

This command:
1. Downloads the `nginx` chart from the `bitnami` repository
2. Names the release `my-nginx`
3. Deploys the resources to your Kubernetes cluster

### Helm Chart Repositories

Helm charts are available from various repositories. You can find public charts at:
- [Artifact Hub](https://artifacthub.io/)
- [Bitnami Charts](https://github.com/bitnami/charts)
- [Helm Hub](https://hub.helm.sh/)

## Summary

In this hands-on section, you've learned how to:

1. Install and configure Minikube for local Kubernetes development
2. Use basic `kubectl` commands to inspect and manage cluster resources
3. Create and manage Deployments and Services using both imperative commands and declarative YAML
4. Scale applications by adjusting replica counts
5. Combine multiple resource definitions in a single YAML file
6. Use Helm as a package manager for Kubernetes

These skills provide a foundation for working with Kubernetes in more complex scenarios. As you become more comfortable with these basics, you can explore advanced topics like StatefulSets, ConfigMaps, Secrets, Ingress, and more.

---

[<- Back: Kubernetes](./05-kubernetes.md) | [Next: System Resilience ->](./07-resilience.md)
