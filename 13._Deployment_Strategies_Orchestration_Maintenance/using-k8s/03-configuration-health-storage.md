# 3. Intermediate: Configuration, Health & Storage 🔧

[<- Back: Basic Two-Server Orchestration & Scaling](./02-orchestration-scaling.md) | [Next: Advanced Professional: Production Readiness ->](./04-production-readiness.md)

## Table of Contents

- [Introduction](#introduction)
- [Key Concepts](#key-concepts)
- [Prerequisites](#prerequisites)
- [Declarative Application Management](#declarative-application-management)
- [Configuring Applications](#configuring-applications)
- [Implementing Health Checks](#implementing-health-checks)
- [Adding Persistent Storage](#adding-persistent-storage)
- [Working with Namespaces](#working-with-namespaces)
- [Manual Deployment Strategies](#manual-deployment-strategies)
- [Summary](#summary)

## Introduction

As we progress in our Kubernetes journey, we need to address more sophisticated requirements for running applications in production. This includes managing application configuration, ensuring application health, persisting data beyond the lifecycle of pods, and implementing more advanced deployment patterns.

In this stage, we'll build upon our basic Kubernetes skills to implement these intermediate concepts, bringing us closer to a production-ready setup. We'll continue to use Minikube for our local environment, but the patterns and practices we learn are directly applicable to production clusters.

## Key Concepts

### ConfigMap

A Kubernetes resource that allows you to decouple configuration from container images. ConfigMaps store non-confidential configuration data as key-value pairs, which can be consumed by pods as environment variables, command-line arguments, or configuration files.

### Secret

Similar to ConfigMaps, but specifically designed for sensitive information such as passwords, tokens, or keys. Secrets are encoded (but not encrypted by default) and provide a way to handle sensitive data separately from application code.

### Liveness Probe

A health check that determines if a container is running properly. If the liveness probe fails, Kubernetes will restart the container to try to resolve the issue.

### Readiness Probe

A health check that determines if a container is ready to accept traffic. If the readiness probe fails, the container's IP address will be removed from the endpoints of any Services that match it, effectively taking it out of service rotation.

### PersistentVolume (PV)

A piece of storage in the cluster that has been provisioned by an administrator or dynamically provisioned using Storage Classes. It's a resource in the cluster just like a node.

### PersistentVolumeClaim (PVC)

A request for storage by a user. Claims can request specific size and access modes (e.g., ReadWriteOnce, ReadOnlyMany, or ReadWriteMany).

### Namespace

A virtual cluster within a Kubernetes cluster. Namespaces provide a way to divide cluster resources between multiple users, teams, or projects.

## Prerequisites

- Completion of Stage 2 (Basic Two-Server Orchestration & Scaling)
- Comfort with Deployments, Services, Scaling, and basic YAML
- Understanding of simple key-value configuration patterns
- Minikube running on your local machine

## Declarative Application Management

Now that we're familiar with using YAML files for resources, let's create a more complete application definition that we'll use throughout this stage.

### Combined Deployment and Service YAML

Create a file named `deployment-service.yaml` with the following content:

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
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "500m"
---
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

Notice that we've added resource requests and limits to our container specification. This is a best practice for production deployments as it helps Kubernetes make better scheduling decisions and prevents containers from consuming excessive resources.

Apply this configuration:

```bash
kubectl apply -f deployment-service.yaml
```

Verify that both resources were created:

```bash
kubectl get deployments,services
```

## Configuring Applications

Applications often require configuration that varies between environments (development, staging, production). Kubernetes provides ConfigMaps and Secrets for managing this configuration.

### Creating a ConfigMap

Let's create a ConfigMap to store some configuration for our application:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  greeting: "Hello from ConfigMap!"
  log_level: "info"
  feature_flags: "enable_feature_a=true,enable_feature_b=false"
```

Save this as `configmap.yaml` and apply it:

```bash
kubectl apply -f configmap.yaml
```

Verify the ConfigMap:

```bash
kubectl get configmaps
kubectl describe configmap app-config
```

### Creating a Secret

For sensitive information like API keys or passwords, use Secrets:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
data:
  api_key: SGVsbG8gZnJvbSB0aGUgb3RoZXIgc2lkZSEK  # Base64 encoded "Hello from the other side!"
```

Save this as `secret.yaml` and apply it:

```bash
kubectl apply -f secret.yaml
```

Verify the Secret:

```bash
kubectl get secrets
kubectl describe secret app-secrets
```

### Using ConfigMaps and Secrets in Pods

Now let's update our deployment to use the ConfigMap and Secret. Modify the `deployment-service.yaml` file:

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
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "500m"
        env:
        - name: GREETING
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: greeting
        - name: LOG_LEVEL
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: log_level
        - name: API_KEY
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: api_key
        volumeMounts:
        - name: config-volume
          mountPath: /etc/config
      volumes:
      - name: config-volume
        configMap:
          name: app-config
---
# Service definition remains the same
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

Apply the updated configuration:

```bash
kubectl apply -f deployment-service.yaml
```

Our application now has:
1. Environment variables from ConfigMap (`GREETING` and `LOG_LEVEL`)
2. Environment variable from Secret (`API_KEY`)
3. A volume that mounts the entire ConfigMap as files under `/etc/config`

### Verifying Configuration

Let's check if our configuration is properly applied:

```bash
# Get one of the pod names
POD_NAME=$(kubectl get pods -l app=k8s-web-hello -o jsonpath='{.items[0].metadata.name}')

# Check environment variables
kubectl exec $POD_NAME -- env | grep -E 'GREETING|LOG_LEVEL|API_KEY'

# Check mounted config files
kubectl exec $POD_NAME -- ls -la /etc/config
kubectl exec $POD_NAME -- cat /etc/config/greeting
```

## Implementing Health Checks

Health checks are crucial for ensuring the reliability of your applications. Kubernetes provides liveness and readiness probes to monitor container health.

### Adding Probes to the Deployment

Let's modify our deployment to include health checks. Update the container spec in `deployment-service.yaml`:

```yaml
containers:
- name: k8s-web-hello
  image: andlocker/k8s-web-hello:latest
  ports:
  - containerPort: 3000
  resources:
    requests:
      memory: "64Mi"
      cpu: "100m"
    limits:
      memory: "128Mi"
      cpu: "500m"
  livenessProbe:
    httpGet:
      path: /healthz
      port: 3000
    initialDelaySeconds: 5
    periodSeconds: 10
  readinessProbe:
    httpGet:
      path: /readyz
      port: 3000
    initialDelaySeconds: 5
    periodSeconds: 5
  env:
  # Environment variables remain the same
```

> **Note**: The `/healthz` and `/readyz` endpoints are common conventions for health check endpoints. Your actual application needs to implement these endpoints for the probes to work correctly.

Apply the updated configuration:

```bash
kubectl apply -f deployment-service.yaml
```

### Understanding Probe Types

- **Liveness Probe**: Determines if a container is running properly. If this fails, Kubernetes will restart the container.
- **Readiness Probe**: Determines if a container is ready to receive traffic. If this fails, the container will be removed from service endpoints.
- **Startup Probe** (not shown above): Determines if an application has started. This is useful for slow-starting containers.

### Probe Implementation Methods

Kubernetes supports several ways to implement probes:

1. **HTTP GET**: Performs an HTTP GET request to a specified path and port
2. **TCP Socket**: Attempts to establish a TCP connection to a specified port
3. **Exec**: Executes a command inside the container

### Checking Probe Status

To see the status of your probes:

```bash
kubectl describe pod $POD_NAME
```

Look for the "Conditions" section, which shows the "Ready" condition, and the "Events" section, which will show probe failures if any.

## Adding Persistent Storage

By default, containers in Kubernetes are ephemeral - when a pod is deleted or replaced, all data inside the container is lost. For applications that need to persist data, Kubernetes provides PersistentVolumes and PersistentVolumeClaims.

### Creating a PersistentVolumeClaim

Create a file named `pvc.yaml`:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```

Apply the PVC:

```bash
kubectl apply -f pvc.yaml
```

Verify that the PVC is created and bound:

```bash
kubectl get pvc
```

When using Minikube, a PersistentVolume is automatically created and bound to your PVC. In a production environment, the PV would be provisioned according to your storage class configuration.

### Using the PVC in a Deployment

Let's update our deployment to use the PVC. Add volumes and volume mounts to the container spec in `deployment-service.yaml`:

```yaml
spec:
  # ... other specs remain the same
  template:
    # ... metadata remains the same
    spec:
      containers:
      - name: k8s-web-hello
        # ... other container specs remain the same
        volumeMounts:
        - name: config-volume
          mountPath: /etc/config
        - name: data-volume
          mountPath: /data
      volumes:
      - name: config-volume
        configMap:
          name: app-config
      - name: data-volume
        persistentVolumeClaim:
          claimName: data-pvc
```

Apply the updated configuration:

```bash
kubectl apply -f deployment-service.yaml
```

### Testing Data Persistence

Let's test that our data truly persists across pod restarts:

```bash
# Write a file to the persistent volume
kubectl exec $POD_NAME -- sh -c "echo 'This data will persist' > /data/test-file.txt"

# Verify the file exists
kubectl exec $POD_NAME -- cat /data/test-file.txt

# Delete the pod (Kubernetes will create a new one)
kubectl delete pod $POD_NAME

# Find the name of the new pod
NEW_POD_NAME=$(kubectl get pods -l app=k8s-web-hello -o jsonpath='{.items[0].metadata.name}')

# Check if the file still exists in the new pod
kubectl exec $NEW_POD_NAME -- cat /data/test-file.txt
```

You should see the file content "This data will persist" in the new pod, demonstrating that the data survived the pod recreation.

## Working with Namespaces

Namespaces provide a way to divide cluster resources between multiple users, teams, or projects. They're especially useful in shared clusters.

### Creating a Namespace

Let's create a namespace for a staging environment:

```bash
kubectl create namespace staging
```

Verify the namespace:

```bash
kubectl get namespaces
```

### Deploying to a Specific Namespace

We can deploy our application to the staging namespace:

```bash
kubectl apply -f deployment-service.yaml -n staging
```

Now our application is running in both the default namespace and the staging namespace. Verify:

```bash
kubectl get pods
kubectl get pods -n staging
```

### Working with Resources in a Namespace

When working with resources in a specific namespace, you'll need to include the `-n` flag in your commands:

```bash
# List services in the staging namespace
kubectl get services -n staging

# Describe a pod in the staging namespace
kubectl describe pod $(kubectl get pods -n staging -o jsonpath='{.items[0].metadata.name}') -n staging
```

Namespaces provide isolation for names, but not for network. By default, services in one namespace can communicate with services in another namespace using the full service name: `<service-name>.<namespace>.svc.cluster.local`.

## Manual Deployment Strategies

Now let's explore manual implementations of advanced deployment strategies.

### Blue-Green Deployment

Blue-Green deployment runs two identical environments, with only one serving production traffic at a time. Let's implement this:

1. Create blue and green deployments:

```yaml
# blue-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: k8s-web-hello-blue
spec:
  replicas: 3
  selector:
    matchLabels:
      app: k8s-web-hello
      version: blue
  template:
    metadata:
      labels:
        app: k8s-web-hello
        version: blue
    spec:
      containers:
      - name: k8s-web-hello
        image: andlocker/k8s-web-hello:v1
        ports:
        - containerPort: 3000
```

```yaml
# green-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: k8s-web-hello-green
spec:
  replicas: 3
  selector:
    matchLabels:
      app: k8s-web-hello
      version: green
  template:
    metadata:
      labels:
        app: k8s-web-hello
        version: green
    spec:
      containers:
      - name: k8s-web-hello
        image: andlocker/k8s-web-hello:v2
        ports:
        - containerPort: 3000
```

2. Create a service that initially points to the blue deployment:

```yaml
# service.yaml
apiVersion: v1
kind: Service
metadata:
  name: k8s-web-hello
spec:
  selector:
    app: k8s-web-hello
    version: blue
  ports:
  - port: 3000
    targetPort: 3000
  type: ClusterIP
```

3. Apply the configurations:

```bash
kubectl apply -f blue-deployment.yaml
kubectl apply -f green-deployment.yaml
kubectl apply -f service.yaml
```

4. To switch traffic from blue to green, update the service selector:

```yaml
# service.yaml (updated)
apiVersion: v1
kind: Service
metadata:
  name: k8s-web-hello
spec:
  selector:
    app: k8s-web-hello
    version: green  # Changed from 'blue' to 'green'
  ports:
  - port: 3000
    targetPort: 3000
  type: ClusterIP
```

```bash
kubectl apply -f service.yaml
```

### Canary Deployment

Canary deployment gradually rolls out changes to a small subset of users. Let's implement a basic version:

1. Deploy the stable version (v1) with multiple replicas:

```yaml
# stable-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: k8s-web-hello-stable
spec:
  replicas: 3
  selector:
    matchLabels:
      app: k8s-web-hello
      version: stable
  template:
    metadata:
      labels:
        app: k8s-web-hello
        version: stable
    spec:
      containers:
      - name: k8s-web-hello
        image: andlocker/k8s-web-hello:v1
        ports:
        - containerPort: 3000
```

2. Deploy the canary version (v2) with fewer replicas:

```yaml
# canary-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: k8s-web-hello-canary
spec:
  replicas: 1
  selector:
    matchLabels:
      app: k8s-web-hello
      version: canary
  template:
    metadata:
      labels:
        app: k8s-web-hello
        version: canary
    spec:
      containers:
      - name: k8s-web-hello
        image: andlocker/k8s-web-hello:v2
        ports:
        - containerPort: 3000
```

3. Create a service that selects pods from both deployments:

```yaml
# canary-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: k8s-web-hello
spec:
  selector:
    app: k8s-web-hello  # Selects both stable and canary
  ports:
  - port: 3000
    targetPort: 3000
  type: ClusterIP
```

4. Apply the configurations:

```bash
kubectl apply -f stable-deployment.yaml
kubectl apply -f canary-deployment.yaml
kubectl apply -f canary-service.yaml
```

With this setup, approximately 25% of traffic (1 out of 4 pods) will go to the canary version. To increase the canary traffic, you can scale up the canary deployment:

```bash
kubectl scale deployment k8s-web-hello-canary --replicas=2
```

Now about 40% of traffic (2 out of 5 pods) will go to the canary version.

## Summary

In this stage, you've learned:

1. How to manage application configuration using ConfigMaps and Secrets
2. How to implement health checks with liveness and readiness probes
3. How to persist data using PersistentVolumeClaims
4. How to work with namespaces to organize and isolate resources
5. How to manually implement blue-green and canary deployment strategies

These intermediate concepts bring us closer to production-ready Kubernetes deployments. We've addressed key concerns like configuration management, application health, data persistence, and deployment strategies, which are essential for running reliable applications in production.

Key takeaways:
- Separate configuration from code using ConfigMaps and Secrets
- Implement health checks to ensure application reliability
- Use persistent storage for data that needs to survive pod restarts
- Leverage namespaces for organizing and isolating resources
- Implement advanced deployment strategies to reduce risk during updates

In the next stage, we'll explore advanced professional topics including working with managed Kubernetes services, implementing CI/CD pipelines, and setting up monitoring and logging.

---

[<- Back: Basic Two-Server Orchestration & Scaling](./02-orchestration-scaling.md) | [Next: Advanced Professional: Production Readiness ->](./04-production-readiness.md)
  