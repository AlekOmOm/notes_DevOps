# 1. From Docker to Your First Pod 🌟

[<- Back: Main Note](./README.md) | [Next: Basic Two-Server Orchestration & Scaling ->](./02-orchestration-scaling.md)

## Table of Contents

- [Introduction](#introduction)
- [Key Concepts](#key-concepts)
- [Prerequisites](#prerequisites)
- [Setting Up Kubernetes Locally](#setting-up-kubernetes-locally)
- [Interacting with Your Cluster](#interacting-with-your-cluster)
- [Running Your First Application](#running-your-first-application)
- [Cleaning Up](#cleaning-up)
- [Summary](#summary)

## Introduction

Docker revolutionized how we package and run applications by introducing containerization. However, managing multiple containers across different environments introduces new challenges that Docker alone doesn't solve effectively. This is where Kubernetes comes in.

This first stage bridges the gap between running individual Docker containers and orchestrating them with Kubernetes. We'll focus on running a simple, existing containerized application locally using Kubernetes' basic building blocks.

## Key Concepts

### Kubernetes (K8s)

Kubernetes is an open-source platform designed to automate deploying, scaling, and operating containerized applications. It groups containers into logical units for easy management and discovery.

### Minikube

Minikube is a tool that runs a single-node Kubernetes cluster locally on your machine. It's perfect for learning Kubernetes or testing deployments locally before pushing to a production cluster.

### kubectl

kubectl is the command-line interface for interacting with Kubernetes clusters. It allows you to run commands against Kubernetes clusters to deploy applications, inspect resources, and view logs.

### Pod

The smallest deployable unit in Kubernetes. A Pod represents a single instance of a running process in a cluster and can contain one or more containers that share storage and network resources.

### Deployment

A Kubernetes resource that manages a replicated application, ensuring a specified number of pod "replicas" are running at any given time. Deployments also handle updating pods to new versions.

### Service

An abstract way to expose an application running on a set of Pods as a network service. Services enable communication between different parts of an application and provide stable endpoints.

## Prerequisites

Before starting, ensure you have:

- Basic understanding of Docker (images, containers, `docker run`, Docker Hub)
- Comfortable with command-line/terminal usage
- Basic awareness of virtual machines as compute resources
- A computer with the following specifications:
  - At least 2 CPU cores
  - At least 2GB of free memory
  - At least 20GB of free disk space
  - Internet connection
  - Container or virtual machine manager (Docker, Hyperkit, VirtualBox, etc.)

## Setting Up Kubernetes Locally

Let's install the necessary tools to run Kubernetes on your local machine.

### Installing kubectl

kubectl is the command-line tool you'll use to interact with your Kubernetes cluster.

**macOS (using Homebrew):**
```bash
brew install kubectl
```

**Windows (using Chocolatey):**
```powershell
choco install kubernetes-cli
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt update
sudo apt install -y kubectl
```

Verify the installation:
```bash
kubectl version --client
```

### Installing Minikube

Minikube is what creates and manages your local Kubernetes cluster.

**macOS (using Homebrew):**
```bash
brew install minikube
```

**Windows (using Chocolatey):**
```powershell
choco install minikube
```

**Linux (Ubuntu/Debian):**
```bash
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
```

### Starting Your Cluster

Now, let's start a Kubernetes cluster using Minikube:

```bash
minikube start --driver=docker
```

This command creates a virtual machine (or uses Docker containers directly) and installs Kubernetes on it. The `--driver` flag specifies which virtualization technology to use. Common options include `docker`, `hyperkit`, `virtualbox`, and `kvm2`, depending on your operating system.

Verify that Minikube is running:

```bash
minikube status
```

You should see output indicating that Minikube is running, and the Kubernetes components are healthy:

```
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured
```

## Interacting with Your Cluster

Now that your cluster is running, let's explore it using kubectl.

### Getting Cluster Information

```bash
kubectl cluster-info
```

This shows the addresses of the control plane and other services.

### Viewing Nodes

```bash
kubectl get nodes
```

In Minikube, you'll see just one node (named `minikube`), which is both the control plane and worker node.

### Exploring Namespaces

Namespaces provide a way to divide cluster resources. Let's see what namespaces exist by default:

```bash
kubectl get namespaces
```

You'll see namespaces like `default`, `kube-system`, and `kube-public`. The `kube-system` namespace contains the components that make Kubernetes work.

Let's see what's running in the `kube-system` namespace:

```bash
kubectl get pods -n kube-system
```

This shows the core Kubernetes components like `etcd`, `kube-apiserver`, and more, all running as pods.

## Running Your First Application

Now, let's deploy a simple application to your Kubernetes cluster. We'll use the official Nginx web server image from Docker Hub.

### Creating a Deployment

```bash
kubectl create deployment nginx --image=nginx
```

This command creates a Deployment named "nginx" that runs the Nginx web server container. Let's see what happened:

```bash
kubectl get deployments
```

You should see your deployment listed. Now check the pods that were created:

```bash
kubectl get pods
```

You should see a pod with a name starting with "nginx-" followed by a random string.

### Understanding What Happened

When you created the Deployment:

1. Kubernetes received the instruction to run one replica of the Nginx container
2. The Deployment created a ReplicaSet to manage the pod(s)
3. The ReplicaSet created the pod
4. Kubernetes scheduled the pod on an available node (in our case, the only Minikube node)
5. The container runtime (Docker) pulled the Nginx image and started the container

### Getting More Details

To see more details about your pod:

```bash
kubectl describe pod <pod-name>
```

Replace `<pod-name>` with the actual name of your pod (from `kubectl get pods`). This command shows detailed information including events, which can be helpful for troubleshooting.

### Exposing Your Application

The Nginx pod is running, but it's not accessible from outside the cluster yet. Let's expose it using a Service:

```bash
kubectl expose deployment nginx --port=80 --type=NodePort
```

This creates a Service that exposes the Nginx deployment on port 80 using a NodePort, which makes it accessible from outside the cluster.

Let's see the service:

```bash
kubectl get services
```

To access the Nginx web server, we need to find out what port Minikube mapped to port 80:

```bash
minikube service nginx --url
```

This command returns a URL that you can open in your browser to see the Nginx welcome page.

Alternatively, you can just run:

```bash
minikube service nginx
```

This will automatically open your default browser to the service URL.

## Cleaning Up

When you're done experimenting, you can clean up the resources you created:

```bash
# Delete the service
kubectl delete service nginx

# Delete the deployment
kubectl delete deployment nginx

# Or delete everything in the default namespace
kubectl delete all --all
```

To stop Minikube when you're done using it:

```bash
minikube stop
```

This stops the Minikube virtual machine but preserves its state. If you want to delete the Minikube VM completely:

```bash
minikube delete
```

## Summary

In this first stage, you've successfully:

1. Set up a local Kubernetes environment using Minikube
2. Learned basic kubectl commands to interact with your cluster
3. Deployed your first application (Nginx) to Kubernetes using a Deployment
4. Exposed your application using a Service
5. Accessed your application through the browser

You've made the crucial transition from thinking in terms of individual containers to Kubernetes objects like Deployments, Pods, and Services. This provides the foundation for the more advanced concepts we'll explore in the next stages.

Key takeaways:
- Kubernetes uses Controllers (like Deployments) to manage applications
- Pods are the basic unit of deployment in Kubernetes
- Services expose applications running in pods
- kubectl is your primary tool for interacting with Kubernetes

In the next stage, we'll explore multi-instance deployment, scaling, and introduce declarative configuration using YAML.

---

[<- Back: Main Note](./README.md) | [Next: Basic Two-Server Orchestration & Scaling ->](./02-orchestration-scaling.md)
