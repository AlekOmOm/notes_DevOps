# Using Kubernetes: Progressive Learning Path 🚀

[Start Learning ->](./01-docker-to-pod.md)

This collection of notes provides a hands-on, practical guide to learning Kubernetes, with a focus on progressive skill-building from basic container orchestration to production-ready deployments.

## Learning Path

1. **[From Docker to Your First Pod](./01-docker-to-pod.md)** 🌟
   - Bridging the gap between Docker and Kubernetes
   - Setting up a local Kubernetes environment with Minikube
   - Running your first application in Kubernetes
   - Understanding core objects: Pods, Deployments, Services

2. **[Basic Two-Server Orchestration & Scaling](./02-orchestration-scaling.md)** 📦
   - Managing applications across multiple (simulated) servers
   - Implementing basic scaling of applications
   - Understanding ReplicaSets and rolling updates
   - Moving from imperative commands to declarative YAML

3. **[Intermediate: Configuration, Health & Storage](./03-configuration-health-storage.md)** ⚡
   - Managing applications declaratively with YAML
   - Configuring applications with ConfigMaps and Secrets
   - Implementing health checks with probes
   - Adding persistent storage with PersistentVolumes
   - Manual implementation of deployment strategies

4. **[Advanced Professional: Production Readiness](./04-production-readiness.md)** 🔄
   - Working with managed Kubernetes services (AKS)
   - Using Helm for application packaging and deployment
   - Implementing CI/CD pipelines for Kubernetes
   - Setting up monitoring, logging, and ingress
   - Introduction to chaos engineering and SRE practices

---

_(These notes are designed for developers and operations professionals who want to progressively build practical Kubernetes skills. Each stage builds upon the previous one, gradually introducing more advanced concepts and patterns.)_

## Prerequisites

- Docker fundamentals (images, containers, Docker Hub)
- Basic command-line proficiency
- Familiarity with YAML syntax (for later stages)
- Cloud provider knowledge (for Stage 4)

## Tools Used

- Minikube (local Kubernetes cluster)
- kubectl (Kubernetes command-line tool)
- Docker (container runtime)
- Helm (package manager for Kubernetes)
- Various cloud provider tools (for Stage 4)

[<- Back to Main Notes](../README.md)
