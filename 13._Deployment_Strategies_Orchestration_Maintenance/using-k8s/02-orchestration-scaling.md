# 2. Basic Two-Server Orchestration & Scaling ⚡

[<- Back: From Docker to Your First Pod](./01-docker-to-pod.md) | [Next: Configuration, Health & Storage ->](./03-configuration-health-storage.md)

## Table of Contents

- [Introduction](#introduction)
- [Key Concepts](#key-concepts)
- [Prerequisites](#prerequisites)
- [Scaling Applications](#scaling-applications)
- [Internal Service Communication](#internal-service-communication)
- [Understanding Rolling Updates](#understanding-rolling-updates)
- [Moving to Declarative Configuration](#moving-to-declarative-configuration)
- [Summary](#summary)

## Introduction

In this stage, we'll build on our basic Kubernetes knowledge to understand how it manages applications across multiple servers and handles scaling. Although we're still using a single-node Minikube cluster, the concepts we'll learn apply to multi-node production clusters.

The ability to seamlessly scale applications and distribute them across multiple servers is one of Kubernetes' core strengths. We'll explore how Kubernetes abstracts away the underlying infrastructure, allowing you to focus on defining the desired state of your application rather than the mechanics of where and how it runs.

## Key Concepts

### Node

A worker machine in Kubernetes, either a virtual machine or physical computer, where containers are deployed. Each node is managed by the control plane and contains the services necessary to run pods.

### ReplicaSet

Ensures that a specified number of pod replicas are running at any given time. If there are too many pods, the ReplicaSet will remove some; if there are too few, it will start more.

### Scaling

The process of adjusting the number of pod replicas to match demand or desired state. Kubernetes can scale applications horizontally (adding more pod instances) based on manual commands or automatic rules.

### Service Types

- **ClusterIP**: Exposes the service on an internal IP within the cluster. Only reachable from within the cluster.
- **NodePort**: Exposes the service on each node's IP at a static port. Accessible from outside the cluster.
- **LoadBalancer**: Exposes the service externally using a cloud provider's load balancer.
- **ExternalName**: Maps the service to the contents of an ExternalName field by returning a CNAME record.

### Rolling Updates

Kubernetes' default method for updating applications, where it gradually replaces old pods with new ones, ensuring zero downtime if configured correctly.

### Declarative Configuration

Defining the desired state of resources using YAML files, rather than using imperative commands. This approach provides better version control, repeatability, and documentation.

## Prerequisites

- Completion of Stage 1 (From Docker to Your First Pod)
- Minikube running on your local machine
- Basic understanding of VMs (conceptualizing multiple machines)
- Limited Terraform knowledge (understanding it can provision multiple VMs)

## Scaling Applications

In production, applications typically run multiple identical instances to provide redundancy and handle increased load. Let's explore how to scale an application in Kubernetes.

### Deploy a Sample Application

We'll use a simple web application for this exercise:

```bash
kubectl create deployment k8s-web-hello --image=andlocker/k8s-web-hello
```

Verify the deployment:

```bash
kubectl get deployments
```

Check the running pod:

```bash
kubectl get pods
```

You should see one pod running.

### Scaling Up

Now, let's scale the application to run multiple instances:

```bash
kubectl scale deployment k8s-web-hello --replicas=3
```

Check the pods again:

```bash
kubectl get pods
```

You should now see three pods running. Let's get more details about where they're running:

```bash
kubectl get pods -o wide
```

In a single-node Minikube environment, all pods run on the same node. However, in a multi-node cluster, Kubernetes would distribute these pods across available nodes based on resource availability and scheduling rules.

### Simulating Multi-Node Behavior

While we're using a single Minikube node, it's important to understand that in a real multi-node cluster:

1. The Kubernetes scheduler would place pods across different nodes to distribute the load.
2. If a node fails, the pods running on it would be rescheduled to other available nodes.
3. The system automatically balances resource utilization across nodes.

To visualize this better, we can use labels to simulate different "logical nodes" even within our single physical node:

```bash
# Let's label some of our pods to simulate them being on different nodes
kubectl label pod $(kubectl get pods -l app=k8s-web-hello -o jsonpath='{.items[0].metadata.name}') node=node1
kubectl label pod $(kubectl get pods -l app=k8s-web-hello -o jsonpath='{.items[1].metadata.name}') node=node2
kubectl label pod $(kubectl get pods -l app=k8s-web-hello -o jsonpath='{.items[2].metadata.name}') node=node3

# Now we can see our "logical" distribution
kubectl get pods -L node
```

## Internal Service Communication

In a microservices architecture, services need to communicate with each other within the cluster. Let's explore how this works using Kubernetes Services.

### Creating an Internal Service

Create an internal ClusterIP service for our application:

```bash
kubectl expose deployment k8s-web-hello --port=3000 --type=ClusterIP
```

Check the service:

```bash
kubectl get services
```

You'll see a ClusterIP service for k8s-web-hello with an internal IP address. This IP is only accessible within the cluster.

### Testing Internal Communication

To verify that our service works and load balances requests across the different pods, we'll create a temporary pod to send requests to our service:

```bash
kubectl run tmp-shell --rm -i --tty --image=ubuntu -- bash
```

Inside this temporary pod, install curl and test the service:

```bash
# Inside the tmp-shell container
apt update
apt install -y curl
curl http://k8s-web-hello:3000
```

Run the curl command multiple times - you might notice subtle differences in the response as requests are load-balanced across different pods.

Type `exit` to leave the temporary pod and return to your terminal.

## Understanding Rolling Updates

When you update an application, Kubernetes performs a rolling update by default, gradually replacing old pods with new ones. Let's see this in action.

### Updating the Deployment

Let's update our deployment's image:

```bash
kubectl set image deployment/k8s-web-hello k8s-web-hello=andlocker/k8s-web-hello:latest
```

Watch the update process in real-time:

```bash
kubectl get pods -w
```

You'll see Kubernetes create new pods and terminate old ones in a controlled manner. This ensures that your application remains available during the update.

Press Ctrl+C to stop watching.

### Understanding Update Strategy

Kubernetes uses a RollingUpdate strategy by default, which ensures:

1. Application remains available (no downtime)
2. Only a certain number of pods are updated at once (default: 25% unavailable, 25% surge)
3. New pods are only considered ready when they pass readiness checks

You can view the update strategy for your deployment:

```bash
kubectl describe deployment k8s-web-hello
```

Look for the "Strategy" field in the output. It should say "RollingUpdate".

## Moving to Declarative Configuration

So far, we've been using imperative commands (`create`, `scale`, `set`). Now, let's move to the declarative approach using YAML files, which is the recommended way to manage Kubernetes resources.

### Exporting Current Configuration

First, let's export our current deployment configuration to a YAML file:

```bash
kubectl get deployment k8s-web-hello -o yaml > deployment.yaml
```

Open this file in a text editor. You'll see it contains many fields, including some status information and auto-generated fields. In practice, you'd create a simpler version with only the required fields.

### Simplifying the YAML

Let's create a simplified version of our deployment YAML. Create a new file called `simple-deployment.yaml` with the following content:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: k8s-web-hello
spec:
  replicas: 3
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
        ports:
        - containerPort: 3000
```

This simplified version includes:
- The API version and kind of resource
- Metadata (name)
- Spec, which includes:
  - Number of replicas
  - Selector to identify which pods are part of this deployment
  - Pod template, which defines the pods to be created

### Applying Declarative Configuration

Let's delete our current deployment and recreate it using our YAML file:

```bash
# Delete the current deployment
kubectl delete deployment k8s-web-hello

# Apply the YAML file
kubectl apply -f simple-deployment.yaml
```

Verify that the deployment is running:

```bash
kubectl get deployments
kubectl get pods
```

### Creating a Service in YAML

Now, let's create a YAML file for our service. Create a file called `service.yaml` with the following content:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: k8s-web-hello
spec:
  selector:
    app: k8s-web-hello
  ports:
  - port: 3000
    targetPort: 3000
  type: ClusterIP
```

Apply the service configuration:

```bash
kubectl apply -f service.yaml
```

Verify that the service is running:

```bash
kubectl get services
```

### Benefits of Declarative Configuration

Using YAML files for configuration provides several benefits:

1. **Version Control**: You can store your configuration in a Git repository.
2. **Documentation**: The YAML files serve as documentation of your infrastructure.
3. **Repeatability**: You can easily recreate the same environment in different clusters.
4. **Validation**: You can validate the configuration before applying it.
5. **Templating**: You can use tools like Helm to template your configuration.

## Summary

In this stage, you've learned:

1. How to scale applications by increasing the number of pod replicas.
2. How Kubernetes distributes pods across nodes (simulated in our single-node environment).
3. How to use ClusterIP services for internal communication between pods.
4. How Kubernetes performs rolling updates to ensure zero downtime.
5. How to move from imperative commands to declarative YAML configuration.

These concepts form the foundation of orchestration and scaling in Kubernetes. While we've been working with a single-node cluster, the principles apply equally to multi-node production environments.

Key takeaways:
- Kubernetes handles the distribution of pods across nodes, abstracting away the underlying infrastructure.
- Services provide a stable endpoint for communication, regardless of how many pods are running or where they're located.
- Declarative configuration with YAML files is the preferred approach for managing Kubernetes resources.

In the next stage, we'll explore more advanced topics including ConfigMaps for configuration, health checks with probes, and persistent storage.

---

[<- Back: From Docker to Your First Pod](./01-docker-to-pod.md) | [Next: Configuration, Health & Storage ->](./03-configuration-health-storage.md)
