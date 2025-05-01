# 4. Advanced Professional: Production Readiness 🚀

[<- Back: Configuration, Health & Storage](./03-configuration-health-storage.md) | [Next: Main Note ->](./README.md)

## Table of Contents

- [Introduction](#introduction)
- [Key Concepts](#key-concepts)
- [Prerequisites](#prerequisites)
- [Managed Kubernetes Services](#managed-kubernetes-services)
- [Helm for Application Packaging](#helm-for-application-packaging)
- [CI/CD Integration](#cicd-integration)
- [GitOps Approaches](#gitops-approaches)
- [Monitoring and Alerting](#monitoring-and-alerting)
- [Logging and Observability](#logging-and-observability)
- [Ingress and External Access](#ingress-and-external-access)
- [Implementing Security Measures](#implementing-security-measures)
- [Chaos Engineering for Resilience](#chaos-engineering-for-resilience)
- [Defining Service Level Objectives](#defining-service-level-objectives)
- [Summary](#summary)

## Introduction

In the final stage of our Kubernetes journey, we transition from a local development environment to a production-ready setup in the cloud. This stage introduces advanced professional concepts and tools that are essential for operating Kubernetes at scale in real-world scenarios.

We'll explore managed Kubernetes services, application packaging, CI/CD integration, monitoring, logging, security, and resilience testing. These topics represent industry best practices for running reliable, secure, and observable Kubernetes applications.

## Key Concepts

### Managed Kubernetes Services

Cloud provider-managed Kubernetes services like Azure Kubernetes Service (AKS), Google Kubernetes Engine (GKE), or Amazon Elastic Kubernetes Service (EKS) handle the management of the Kubernetes control plane, reducing operational complexity.

### Helm

Kubernetes package manager that helps you define, install, and upgrade even the most complex Kubernetes applications. Helm uses "charts" that contain pre-configured Kubernetes resources.

### CI/CD Integration

Continuous Integration and Continuous Deployment pipelines automate the building, testing, and deployment of applications to Kubernetes clusters.

### GitOps

An operational framework that takes DevOps best practices used for application development such as version control, collaboration, compliance, and CI/CD, and applies them to infrastructure automation.

### Monitoring and Alerting

Systems to collect, store, and visualize metrics from Kubernetes clusters and applications, and to alert operators when issues arise.

### Logging and Observability

Tools to collect, aggregate, and search logs from all components in a Kubernetes cluster, as well as to trace requests across distributed systems.

### Ingress

A Kubernetes resource that manages external access to services in a cluster, typically HTTP/HTTPS routing.

### Security Measures

Techniques and tools to secure Kubernetes clusters, including network policies, RBAC, and pod security policies.

### Chaos Engineering

The discipline of experimenting on a system to build confidence in its capability to withstand turbulent conditions in production.

### Service Level Objectives (SLOs)

Targets for the reliability and performance of a service, often expressed as metrics like availability percentage or latency.

## Prerequisites

- Completion of Stage 3 (Configuration, Health & Storage)
- Basic understanding of CI/CD concepts
- Familiarity with cloud provider basics (e.g., Azure, AWS, GCP)
- More robust Terraform knowledge (ability to provision cloud resources)
- Access to a cloud provider account (Azure used in examples)

## Managed Kubernetes Services

While Minikube is excellent for learning and development, production workloads typically run on managed Kubernetes services provided by cloud providers.

### Azure Kubernetes Service (AKS)

Azure Kubernetes Service (AKS) is Microsoft Azure's managed Kubernetes service. Let's see how to provision an AKS cluster using Terraform.

Create a file named `main.tf` with the following content:

```hcl
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "my-aks-rg"
  location = "East US"
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "my-aks-cluster"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "myakscluster"

  default_node_pool {
    name       = "default"
    node_count = 2
    vm_size    = "Standard_DS2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "Production"
  }
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive = true
}
```

This Terraform configuration:
1. Creates a resource group in Azure
2. Provisions an AKS cluster with 2 nodes
3. Outputs the kubeconfig file that allows kubectl to connect to the cluster

To deploy the AKS cluster:

```bash
# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply
```

Once the cluster is deployed, configure kubectl to connect to it:

```bash
# Save the kubeconfig to a file
terraform output -raw kube_config > ~/.kube/config-aks

# Set the KUBECONFIG environment variable
export KUBECONFIG=~/.kube/config-aks

# Verify the connection
kubectl get nodes
```

> **Note**: In a production environment, you would include additional configuration for networking, monitoring, and security. The above example is simplified for clarity.

## Helm for Application Packaging

Helm is a package manager for Kubernetes that allows you to define, install, and upgrade applications using "charts". A Helm chart is a collection of files that describe a related set of Kubernetes resources.

### Installing Helm

```bash
# macOS (using Homebrew)
brew install helm

# Windows (using Chocolatey)
choco install kubernetes-helm

# Linux
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### Creating a Helm Chart for Our Application

Let's create a Helm chart for our `k8s-web-hello` application:

```bash
helm create k8s-web-hello
```

This command creates a directory structure with template files. Let's modify these files to fit our application:

1. Edit `k8s-web-hello/values.yaml` to set default values:

```yaml
replicaCount: 3

image:
  repository: andlocker/k8s-web-hello
  tag: latest
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 3000

ingress:
  enabled: false

resources:
  limits:
    cpu: 500m
    memory: 128Mi
  requests:
    cpu: 100m
    memory: 64Mi

livenessProbe:
  httpGet:
    path: /healthz
    port: http
  initialDelaySeconds: 5
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /readyz
    port: http
  initialDelaySeconds: 5
  periodSeconds: 5

persistence:
  enabled: true
  size: 1Gi

configMap:
  greeting: "Hello from ConfigMap!"
  log_level: "info"
```

2. The templates directory already contains the Kubernetes resource definitions, but you may need to adjust them to match our application's needs.

### Installing the Helm Chart

Once your chart is ready, you can install it:

```bash
helm install web-app ./k8s-web-hello
```

Verify the installation:

```bash
helm list
kubectl get all
```

### Upgrading the Helm Chart

To update your application, modify the values or templates, and upgrade the release:

```bash
# Update the version in values.yaml
helm upgrade web-app ./k8s-web-hello
```

### Rolling Back a Helm Release

If an upgrade causes issues, you can easily roll back:

```bash
# List the revision history
helm history web-app

# Roll back to a specific revision
helm rollback web-app 1
```

## CI/CD Integration

Modern development workflows automate the build, test, and deployment processes using CI/CD pipelines. Let's look at how to integrate Kubernetes deployments into a CI/CD pipeline using GitHub Actions.

### Setting Up a GitHub Actions Workflow

Create a file at `.github/workflows/deploy.yml` in your repository:

```yaml
name: Build and Deploy

on:
  push:
    branches: [ main ]

env:
  ACR_REGISTRY: myacr.azurecr.io
  IMAGE_NAME: k8s-web-hello
  AKS_CLUSTER: my-aks-cluster
  AKS_RESOURCE_GROUP: my-aks-rg

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v1
    
    - name: Login to ACR
      uses: docker/login-action@v1
      with:
        registry: ${{ env.ACR_REGISTRY }}
        username: ${{ secrets.ACR_USERNAME }}
        password: ${{ secrets.ACR_PASSWORD }}
    
    - name: Build and push
      uses: docker/build-push-action@v2
      with:
        context: .
        push: true
        tags: ${{ env.ACR_REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
    
    - name: Set up kubectl
      uses: azure/setup-kubectl@v1
    
    - name: Set up Helm
      uses: azure/setup-helm@v1
    
    - name: Set AKS context
      uses: azure/aks-set-context@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}
        resource-group: ${{ env.AKS_RESOURCE_GROUP }}
        cluster-name: ${{ env.AKS_CLUSTER }}
    
    - name: Deploy to AKS
      run: |
        # Update the image tag in the Helm values file
        sed -i "s|tag:.*|tag: ${{ github.sha }}|" ./k8s-web-hello/values.yaml
        
        # Install or upgrade the Helm chart
        helm upgrade --install web-app ./k8s-web-hello
```

This workflow:
1. Builds a Docker image from your application code
2. Pushes the image to Azure Container Registry (ACR)
3. Updates the Helm chart with the new image tag
4. Deploys the updated Helm chart to AKS

To use this workflow, you'll need to set up the following secrets in your GitHub repository:
- `ACR_USERNAME` and `ACR_PASSWORD`: Credentials for your Azure Container Registry
- `AZURE_CREDENTIALS`: Service principal credentials for Azure

## GitOps Approaches

GitOps is an operational framework that applies DevOps best practices to infrastructure automation. In a GitOps model, the desired state of your infrastructure is stored in Git, and automated processes ensure the actual state matches the desired state.

### Flux CD

Flux is a tool that ensures Kubernetes clusters are configured per the manifests stored in Git repositories. Here's how to set up Flux:

1. Install the Flux CLI:

```bash
# macOS
brew install fluxcd/tap/flux

# Other platforms
curl -s https://fluxcd.io/install.sh | bash
```

2. Check if your cluster is ready for Flux:

```bash
flux check --pre
```

3. Bootstrap Flux on your cluster:

```bash
flux bootstrap github \
  --owner=your-github-username \
  --repository=your-repo-name \
  --path=clusters/my-cluster \
  --personal
```

This will:
- Create a repository if it doesn't exist
- Add Flux components to your cluster
- Configure Flux to sync the specified path

4. Create a simple application deployment:

```bash
# Create a directory for your application
mkdir -p clusters/my-cluster/apps/web-app

# Create a kustomization.yaml file
cat > clusters/my-cluster/apps/web-app/kustomization.yaml << EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: web-app-network-policy
spec:
  podSelector:
    matchLabels:
      app: k8s-web-hello
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 3000
```

This NetworkPolicy only allows pods with the label `app: frontend` to communicate with our `k8s-web-hello` pods on port 3000.

Apply the NetworkPolicy:

```bash
kubectl apply -f network-policy.yaml
```

### Role-Based Access Control (RBAC)

RBAC controls who can access the Kubernetes API and what actions they can perform. Create a file named `rbac.yaml`:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-service-account
  namespace: default
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: app-role
  namespace: default
rules:
- apiGroups: [""]
  resources: ["pods", "services"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: app-role-binding
  namespace: default
subjects:
- kind: ServiceAccount
  name: app-service-account
  namespace: default
roleRef:
  kind: Role
  name: app-role
  apiGroup: rbac.authorization.k8s.io
```

This RBAC configuration:
1. Creates a service account for your application
2. Creates a role that allows reading pods and services
3. Binds the role to the service account

Apply the RBAC configuration:

```bash
kubectl apply -f rbac.yaml
```

Update your deployment to use the service account:

```yaml
spec:
  template:
    spec:
      serviceAccountName: app-service-account
      containers:
      # ...
```

### Pod Security Context

Add security context to your pod specification to enhance security:

```yaml
spec:
  template:
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 2000
      containers:
      - name: k8s-web-hello
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
            - ALL
```

These settings:
1. Run the container as a non-root user
2. Prevent privilege escalation
3. Make the root filesystem read-only
4. Drop all Linux capabilities

## Chaos Engineering for Resilience

Chaos engineering involves deliberately injecting failures into your system to test its resilience. Let's create a simple chaos engineering tool to randomly delete pods.

Create a file named `keasmonkey.sh`:

```bash
#!/bin/bash

while true
do
    echo "Choosing a pod to kill..."

    PODS=$(kubectl get pods -l app=k8s-web-hello | grep -v NAME | awk '{print $1}')
    POD_COUNT=$(kubectl get pods -l app=k8s-web-hello | grep -v NAME | wc -l)

    if [ "$POD_COUNT" -eq 0 ]; then
        echo "No pods found. Exiting loop."
        break
    fi

    K=$(( (RANDOM % POD_COUNT) + 1))

    TARGET_POD=$(kubectl get pods -l app=k8s-web-hello | grep -v NAME | awk '{print $1}' | head -n ${K} | tail -n 1)

    echo "Killing pod $TARGET_POD"
    kubectl delete pod $TARGET_POD

    sleep 60
done
```

Make the script executable and run it:

```bash
chmod +x keasmonkey.sh
./keasmonkey.sh
```

This script will randomly delete one of your application pods every minute. Observe how Kubernetes automatically recreates the pods to maintain the desired replica count.

For more sophisticated chaos testing, consider using tools like:
- Chaos Mesh
- Litmus Chaos
- Gremlin

## Defining Service Level Objectives

Service Level Objectives (SLOs) define the target level of reliability for your service. Let's define some SLOs for our application:

1. **Availability**: 99.9% uptime measured over 30 days
2. **Latency**: 95% of requests complete in less than 200ms
3. **Error Rate**: Less than 0.1% of requests result in 5xx errors

To monitor these SLOs, set up Prometheus recording rules:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-slos
  namespace: monitoring
data:
  slos.yml: |
    groups:
    - name: slos
      rules:
      - record: slo:availability:ratio
        expr: sum(rate(http_requests_total{job="k8s-web-hello",code!~"5.."}[5m])) / sum(rate(http_requests_total{job="k8s-web-hello"}[5m]))
      - record: slo:latency:ratio
        expr: sum(rate(http_request_duration_seconds_bucket{job="k8s-web-hello",le="0.2"}[5m])) / sum(rate(http_request_duration_seconds_count{job="k8s-web-hello"}[5m]))
      - record: slo:error:ratio
        expr: sum(rate(http_requests_total{job="k8s-web-hello",code=~"5.."}[5m])) / sum(rate(http_requests_total{job="k8s-web-hello"}[5m]))
```

Create a Grafana dashboard to visualize these SLOs and track your error budget over time.

## Summary

Congratulations! You've now covered the advanced professional concepts needed to run Kubernetes in production. In this stage, you've learned:

1. How to provision and manage a managed Kubernetes service (AKS)
2. How to package applications using Helm for easier deployment and upgrades
3. How to implement CI/CD pipelines for automated deployments
4. How to use GitOps approaches for declarative infrastructure management
5. How to set up monitoring, alerting, and logging for observability
6. How to secure external access to your applications using Ingress controllers
7. How to implement security measures including network policies and RBAC
8. How to test resilience using chaos engineering
9. How to define and monitor Service Level Objectives

These advanced concepts represent industry best practices for running reliable, secure, and observable Kubernetes applications in production environments.

Key takeaways:
- Use managed Kubernetes services for reduced operational overhead
- Implement proper CI/CD and GitOps for automation and consistency
- Ensure observability through comprehensive monitoring and logging
- Secure your applications with network policies, RBAC, and secure contexts
- Test resilience proactively through chaos engineering
- Define and track SLOs to maintain reliability

Remember that production-grade Kubernetes requires careful planning and continuous improvement. Start with what you need, and gradually adopt more advanced patterns as your requirements evolve.

---

[<- Back: Configuration, Health & Storage](./03-configuration-health-storage.md) | [Next: Main Note ->](./README.md) kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
  - service.yaml
EOF

# Create a deployment.yaml file
cat > clusters/my-cluster/apps/web-app/deployment.yaml << EOF
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
EOF

# Create a service.yaml file
cat > clusters/my-cluster/apps/web-app/service.yaml << EOF
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
EOF

# Commit and push the changes
git add .
git commit -m "Add web-app manifests"
git push
```

Flux will automatically detect the changes in your Git repository and apply them to your cluster.

## Monitoring and Alerting

Monitoring is essential for understanding the health and performance of your Kubernetes cluster and applications. Let's set up Prometheus and Grafana for monitoring.

### Installing Prometheus and Grafana Using Helm

```bash
# Add the Prometheus community Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Create a namespace for monitoring
kubectl create namespace monitoring

# Install Prometheus
helm install prometheus prometheus-community/prometheus \
  --namespace monitoring

# Install Grafana
helm repo add grafana https://grafana.github.io/helm-charts
helm install grafana grafana/grafana \
  --namespace monitoring \
  --set persistence.enabled=true \
  --set adminPassword=admin
```

### Accessing Grafana

```bash
# Get the Grafana password
kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

# Port-forward to access Grafana
kubectl port-forward --namespace monitoring svc/grafana 3000:80
```

Open your browser to http://localhost:3000 and log in with username `admin` and the password retrieved above.

### Setting Up Dashboards

In Grafana:
1. Go to Configuration > Data Sources
2. Add Prometheus as a data source (URL: http://prometheus-server)
3. Import dashboards from the Grafana Dashboard catalog:
   - Kubernetes Cluster Overview (dashboard ID: 10856)
   - Node Exporter Full (dashboard ID: 1860)

### Creating Alerts

In Prometheus:
1. Define alerting rules in a ConfigMap:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-alerts
  namespace: monitoring
data:
  alerts.yml: |
    groups:
    - name: k8s-web-hello
      rules:
      - alert: HighErrorRate
        expr: sum(rate(http_requests_total{job="k8s-web-hello",code=~"5.."}[5m])) / sum(rate(http_requests_total{job="k8s-web-hello"}[5m])) > 0.05
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High error rate on k8s-web-hello"
          description: "Error rate is {{ $value | humanizePercentage }} over the last 5 minutes"
```

2. Apply the ConfigMap and configure Prometheus to use it.

## Logging and Observability

Centralized logging is crucial for troubleshooting issues in distributed systems. Let's set up the Elastic Stack (Elasticsearch, Filebeat, Kibana) for logging.

### Installing the Elastic Stack Using Helm

```bash
# Add the Elastic Helm repository
helm repo add elastic https://helm.elastic.co
helm repo update

# Create a namespace for logging
kubectl create namespace logging

# Install Elasticsearch
helm install elasticsearch elastic/elasticsearch \
  --namespace logging \
  --set replicas=1 \
  --set minimumMasterNodes=1 \
  --set resources.requests.cpu="100m" \
  --set resources.requests.memory="1Gi" \
  --set resources.limits.cpu="1000m" \
  --set resources.limits.memory="2Gi"

# Install Kibana
helm install kibana elastic/kibana \
  --namespace logging \
  --set elasticsearchHosts=http://elasticsearch-master:9200

# Install Filebeat
helm install filebeat elastic/filebeat \
  --namespace logging \
  --set elasticsearchHosts=http://elasticsearch-master:9200
```

### Accessing Kibana

```bash
# Port-forward to access Kibana
kubectl port-forward --namespace logging svc/kibana-kibana 5601:5601
```

Open your browser to http://localhost:5601 to access Kibana.

### Setting Up Log Collection

Filebeat automatically collects container logs from your Kubernetes cluster. In Kibana:
1. Go to Management > Stack Management > Index Patterns
2. Create an index pattern for `filebeat-*`
3. Navigate to Discover to view logs

## Ingress and External Access

In production, you'll want to expose your applications to the internet using Ingress controllers, which provide HTTP/HTTPS routing, SSL termination, and more.

### Installing Nginx Ingress Controller

```bash
# Add the Ingress Nginx Helm repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Install the Ingress Nginx controller
helm install nginx-ingress ingress-nginx/ingress-nginx
```

### Creating an Ingress Resource

Create a file named `ingress.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: k8s-web-hello
  annotations:
    kubernetes.io/ingress.class: nginx
spec:
  rules:
  - host: hello.example.com  # Replace with your domain
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: k8s-web-hello
            port:
              number: 3000
```

Apply the Ingress resource:

```bash
kubectl apply -f ingress.yaml
```

Configure DNS to point your domain (e.g., hello.example.com) to the external IP of the Ingress controller:

```bash
kubectl get service nginx-ingress-ingress-nginx-controller
```

### Adding SSL/TLS

To enable HTTPS, add a TLS section to your Ingress resource:

```yaml
spec:
  tls:
  - hosts:
    - hello.example.com
    secretName: hello-tls
  rules:
  # ...
```

Create a TLS secret with your certificate:

```bash
kubectl create secret tls hello-tls \
  --key /path/to/private.key \
  --cert /path/to/certificate.crt
```

Alternatively, you can use cert-manager to automatically manage SSL certificates.

## Implementing Security Measures

Security is a critical concern in production Kubernetes environments. Let's explore some security measures:

### Network Policies

Network Policies control the traffic flow between pods. Create a file named `network-policy.yaml`:

```yaml
apiVersion: