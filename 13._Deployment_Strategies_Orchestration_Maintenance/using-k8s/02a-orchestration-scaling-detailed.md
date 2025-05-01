# 2a. Basic Orchestration & Scaling - Detailed Guide 🔄

[<- Back: Docker to Your First Pod](./02-orchestration-scaling.md) | [Next: Configuration, Health & Storage ->](./03-configuration-health-storage.md)

## Overview

This detailed sub-note expands on basic Kubernetes concepts by diving into how Kubernetes handles multiple instances of your application, performs rolling updates, and introduces the declarative approach to resource management using YAML files. It builds upon the foundations established in Stage 1.

## Key Concepts

### Nodes and Replicas

In a production Kubernetes cluster, your applications run across multiple physical or virtual machines called "nodes." When you deploy multiple copies (replicas) of your application, Kubernetes distributes them across these nodes for better fault tolerance and load distribution.

### Scaling

Scaling refers to adjusting the number of running instances of your application to meet demand. Kubernetes makes it easy to scale applications up or down without downtime.

### Rolling Updates

When you need to update your application, Kubernetes can perform rolling updates, gradually replacing old pods with new ones to ensure zero downtime.

### Declarative Configuration

Instead of using imperative commands to tell Kubernetes what to do step-by-step, the declarative approach involves defining the desired state in YAML files, letting Kubernetes figure out how to achieve that state.

## Implementation Steps

### 1. Understanding Nodes and Replicas

While Minikube provides only a single-node cluster for local development, the concepts of scaling and pod distribution still apply:

Check your cluster's nodes:
```bash
kubectl get nodes
```

You'll only see one node named `minikube`. In a real cluster (like AKS on Azure), you'd see multiple nodes, and Kubernetes would automatically spread your application pods across them.

### 2. Deploying and Scaling an Application

Let's deploy a sample Node.js application and scale it to multiple replicas:

#### Create the Deployment

```bash
kubectl create deployment hello-app --image=andlocker/k8s-web-hello
```

Verify the deployment:
```bash
kubectl get deployments hello-app
```

Check the pod:
```bash
kubectl get pods -l app=hello-app
```

You should see one pod running.

#### Scale Up to Multiple Replicas

Now, let's tell Kubernetes to run three copies of our application:

```bash
kubectl scale deployment hello-app --replicas=3
```

Verify the scaling:
```bash
kubectl get pods -l app=hello-app
```

You should now see three pods running, all with similar names starting with `hello-app-`.

#### View Node Assignment

To see which node each pod is running on:

```bash
kubectl get pods -l app=hello-app -o wide
```

In Minikube, all pods will show the same `minikube` node. In a multi-node cluster, you'd see pods distributed across different nodes.

### 3. Internal Service and Load Balancing

When an application has multiple replicas, Kubernetes needs to distribute incoming requests across them. Let's create an internal service for this:

#### Create a ClusterIP Service

```bash
kubectl expose deployment hello-app --port=3000 --target-port=3000 --type=ClusterIP --name=hello-service
```

This creates a service with an internal cluster IP that load-balances requests across all pods in the deployment.

Check the service:
```bash
kubectl get service hello-service
```

Note the `TYPE` is `ClusterIP` and there's a `CLUSTER-IP` listed (e.g., `10.100.x.x`).

#### Test Internal Load Balancing

Let's run a temporary pod inside the cluster to test the service:

```bash
kubectl run tmp-client --rm -i --tty --image=busybox -- sh
```

Once you get a shell prompt, run:
```bash
wget -qO- http://hello-service:3000
```

You should get a response from one of the pods. If you run this command multiple times, Kubernetes will distribute requests across all three pods.

Type `exit` to leave the temporary pod.

### 4. Performing a Rolling Update

Kubernetes performs updates by gradually replacing old pods with new ones, ensuring zero downtime:

#### Trigger an Update

```bash
kubectl set image deployment/hello-app hello-app=andlocker/k8s-web-hello:latest --record
```

The `--record` flag records this command in the revision history.

#### Watch the Rolling Update Process

```bash
kubectl rollout status deployment/hello-app
```

In another terminal, you can see the pods being replaced:
```bash
kubectl get pods -l app=hello-app -w
```

You'll see new pods being created and old pods terminating one by one until all pods are running the new version.

#### View Update History and Rollback (Optional)

```bash
# View revision history
kubectl rollout history deployment/hello-app

# Roll back to previous version
kubectl rollout undo deployment/hello-app
```

### 5. Introduction to Declarative Management (YAML)

The imperative commands we've been using are convenient for quick operations, but production Kubernetes deployments use the declarative approach with YAML files:

#### Export Existing Deployment to YAML

Let's see what the YAML for our deployment looks like:

```bash
kubectl get deployment hello-app -o yaml > hello-app-deployment.yaml
```

Open this file in a text editor. You'll see:
- `apiVersion`: Kubernetes API version
- `kind`: Type of resource (Deployment)
- `metadata`: Name, labels, etc.
- `spec`: The desired state, including:
  - `replicas`: Number of pods to run
  - `selector`: How to identify pods managed by this deployment
  - `template`: Pod definition

#### Simplify the YAML

The exported YAML contains many auto-generated fields we don't need. Let's create a simplified version in a new file called `simple-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: hello-app
  template:
    metadata:
      labels:
        app: hello-app
    spec:
      containers:
      - name: hello-app
        image: andlocker/k8s-web-hello
        ports:
        - containerPort: 3000
```

#### Apply the Declarative Configuration

Delete the existing deployment:
```bash
kubectl delete deployment hello-app
```

Create it again using the YAML file:
```bash
kubectl apply -f simple-deployment.yaml
```

Verify it's running:
```bash
kubectl get deployments
kubectl get pods -l app=hello-app
```

#### Create a Service in YAML

Let's also define our service declaratively. Create a file called `service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: hello-service
spec:
  selector:
    app: hello-app
  ports:
  - port: 3000
    targetPort: 3000
  type: ClusterIP
```

Apply the service configuration:
```bash
kubectl apply -f service.yaml
```

#### Combine Resources in a Single File

For simpler management, you can define multiple resources in a single YAML file separated by `---`. Create a file called `combined.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: hello-app
  template:
    metadata:
      labels:
        app: hello-app
    spec:
      containers:
      - name: hello-app
        image: andlocker/k8s-web-hello
        ports:
        - containerPort: 3000
---
apiVersion: v1
kind: Service
metadata:
  name: hello-service
spec:
  selector:
    app: hello-app
  ports:
  - port: 3000
    targetPort: 3000
  type: ClusterIP
```

Apply both resources at once:
```bash
kubectl apply -f combined.yaml
```

### 6. Clean Up

When you're done experimenting, clean up the resources:

```bash
# Delete resources using YAML file
kubectl delete -f combined.yaml

# Or delete everything
kubectl delete all --all
```

## Common Challenges and Solutions

### Challenge 1: Pods Not Scheduling

**Problem:** Pods stay in `Pending` state after scaling up.

**Solution:**

```bash
# Check pod status details
kubectl describe pod <pod-name>

# Check node resource availability
kubectl describe node minikube

# Reduce resource requests if necessary by editing the deployment
kubectl edit deployment hello-app
```

### Challenge 2: Rolling Update Stuck

**Problem:** Rolling update doesn't complete.

**Solution:**

```bash
# Check rollout status
kubectl rollout status deployment/hello-app

# Check events for errors
kubectl get events

# If necessary, force the rollout to continue
kubectl rollout resume deployment/hello-app

# Or abort and rollback
kubectl rollout undo deployment/hello-app
```

## Practical Example

This example shows how to deploy, scale, update, and finally convert to a declarative approach:

```bash
# Start with imperative commands
kubectl create deployment web-app --image=nginx

# Scale up
kubectl scale deployment web-app --replicas=3

# Expose internally
kubectl expose deployment web-app --type=ClusterIP --port=80 --name=web-service

# Update image
kubectl set image deployment/web-app nginx=nginx:alpine

# Export to YAML
kubectl get deployment web-app -o yaml > web-app-deployment.yaml
kubectl get service web-service -o yaml > web-app-service.yaml

# Clean up imperative resources
kubectl delete deployment web-app
kubectl delete service web-service

# Apply from YAML
kubectl apply -f web-app-deployment.yaml
kubectl apply -f web-app-service.yaml
```

## Summary

In this stage, you've learned:

1. How to scale an application to multiple replicas
2. How Kubernetes distributes pods across nodes (conceptually, even in Minikube)
3. How to create a Service for internal communication and load balancing
4. How Kubernetes performs rolling updates for zero-downtime deployments
5. How to move from imperative commands to declarative YAML files

These skills form the foundation for more advanced Kubernetes concepts, such as configuration management, health checks, and persistent storage, which will be covered in the next stage.

## Next Steps

Now that you understand basic scaling and orchestration, you're ready to explore more advanced topics like:
- Managing application configuration with ConfigMaps and Secrets
- Implementing health checks with probes
- Adding persistent storage with PersistentVolumes
- Working with namespaces

---

[<- Back: Docker to Your First Pod](./02-orchestration-scaling.md) | [Next: Configuration, Health & Storage ->](./03-configuration-health-storage.md)
