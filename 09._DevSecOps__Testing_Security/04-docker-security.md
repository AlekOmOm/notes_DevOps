# 4. Docker Security and Firewalls 🐳

[<- Back: DevSecOps Implementation](./03-devsecops-implementation.md) | [Next: Continuous Testing ->](./05-continuous-testing.md)

---
- [4a - Docker Security Fundamentals](./04a-docker-security-fundamentals.md)
- [4b - Firewall Configuration](./04b-firewall-configuration.md)
- [4c - Container Isolation](./04c-container-isolation.md)
---

## Table of Contents

- [Container Security Foundations](#container-security-foundations)
- [Docker Security Challenges](#docker-security-challenges)
- [Firewall Concepts](#firewall-concepts)
- [Docker and Firewall Interactions](#docker-and-firewall-interactions)
- [Network Security Best Practices](#network-security-best-practices)
- [Privilege Management](#privilege-management)
- [Docker Security Implementation](#docker-security-implementation)

## Container Security Foundations

Containerization introduces unique security considerations that differ from traditional virtualization. While containers share the host OS kernel, leading to significant performance benefits, this architectural choice introduces security implications that must be systematically addressed.

### Isolation Fundamentals

Container security operates on multiple isolation layers:

1. **Namespace isolation**: Segregates process trees, network interfaces, and mount points
2. **Control group isolation**: Restricts resource consumption
3. **Capability limitations**: Constrains privileged operations
4. **Seccomp profiles**: Filters system calls

### Security Boundaries

Understanding container boundaries is essential for proper security implementation:

- Containers provide **process isolation**, not complete virtualization
- The host kernel remains a **shared resource**
- Container breakout attacks target the **boundary between container and host**
- Network connections between containers represent potential **lateral movement vectors**

## Docker Security Challenges

Docker deployments face several inherent security challenges:

### Image Supply Chain Risks

Container images introduce potential vulnerabilities through:

- **Base image vulnerabilities**: Inherited security issues
- **Dependency vulnerabilities**: Libraries with known CVEs
- **Image tampering**: Unauthorized modification during distribution

### Runtime Vulnerabilities

Running containers face dynamic threats:

- **Privilege escalation**: Gaining elevated permissions
- **Resource exhaustion**: DoS attacks through resource consumption
- **Container breakout**: Escaping container boundaries
- **Poisoned volumes**: Compromised mounted data

### Network Attack Surface

Containerized applications face network-specific risks:

- **Container-to-container attacks**: Lateral movement
- **Exposed ports**: Unintended network exposure
- **Man-in-the-middle**: Network traffic interception
- **Port scanning**: Service discovery for attacks

## Firewall Concepts

Firewalls provide essential network traffic control and represent a critical security boundary.

### Firewall Types

Modern infrastructure utilizes multiple firewall implementations:

#### Packet-filtering Firewalls
- Operate at network layer (Layer 3)
- Filter based on IP addresses and ports
- Stateless operation (each packet evaluated individually)

#### Stateful Firewalls
- Track connection state
- Make decisions based on context
- More effective against certain attacks

#### Proxy Firewalls
- Intermediate for connection requests
- Deep packet inspection
- Application-level filtering

#### Next-generation Firewalls (NGFW)
- Combine traditional firewall capabilities with advanced features
- Intrusion prevention
- Application awareness
- User identity integration

### Linux Firewall Implementations

Linux systems typically use one of two primary firewall technologies:

#### iptables
Low-level, powerful firewall framework:

```bash
# Display current firewall rules
sudo iptables -L

# Allow incoming HTTP traffic
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT

# Block specific IP address
sudo iptables -A INPUT -s 192.168.1.100 -j DROP

# Allow SSH from specific IP
sudo iptables -A INPUT -p tcp -s 192.168.1.101 --dport 22 -j ACCEPT
```

#### ufw (Uncomplicated Firewall)
Higher-level interface for iptables:

```bash
# Check firewall status
sudo ufw status

# Enable firewall
sudo ufw enable

# Allow SSH connections
sudo ufw allow ssh

# Allow specific port
sudo ufw allow 8080/tcp
```

## Docker and Firewall Interactions

Docker's networking model creates unique challenges for firewall management.

### Docker Networking Architecture

Docker networking operates through:

1. **Bridge networks**: Default internal networks
2. **Host networks**: Shared with host networking stack
3. **Overlay networks**: Multi-host container communication
4. **Macvlan networks**: Direct assignment of MAC addresses

### Firewall Bypass Issue

A critical security consideration: **Docker can bypass UFW (Uncomplicated Firewall) rules by directly manipulating iptables**.

When container ports are published, Docker:
1. Creates iptables rules to forward traffic
2. Bypasses UFW's rule processing
3. Potentially exposes services unintentionally

This behavior occurs because:
- Docker inserts rules at a higher priority than UFW
- UFW's rules don't get processed for connections to published ports
- Published ports become accessible regardless of UFW configuration

### Mitigation Strategies

Several approaches can address this security issue:

#### 1. IP-restricted Port Publishing

Limit port exposure to specific interfaces:

```yaml
# docker-compose.yml
services:
  internal_service:
    ports:
      - "127.0.0.1:8080:8080"  # Only accessible from localhost
      
  public_service:
    ports:
      - "80:80"  # Accessible from any interface
```

#### 2. Docker Networking Configuration

Modify Docker's default behavior:

```json
// /etc/docker/daemon.json
{
  "iptables": false
}
```

This prevents Docker from manipulating iptables, but requires manual network configuration.

#### 3. External Firewall Layer

Implement cloud provider firewall rules that operate outside the VM:
- AWS Security Groups
- GCP Firewall Rules
- Azure Network Security Groups

## Network Security Best Practices

Beyond firewall configuration, container deployments should implement comprehensive network security practices.

### Network Segmentation

Implement isolation between container groups:

```yaml
# docker-compose.yml with network segmentation
services:
  frontend:
    networks:
      - frontend_net
      
  api:
    networks:
      - frontend_net
      - backend_net
      
  database:
    networks:
      - backend_net
      
networks:
  frontend_net:
  backend_net:
```

### Least Privilege Network Access

Implement rules allowing only necessary connections:

```bash
# Allow only essential connections to database
sudo iptables -A FORWARD -p tcp -d db_container_ip --dport 5432 -s api_container_ip -j ACCEPT
sudo iptables -A FORWARD -p tcp -d db_container_ip --dport 5432 -j DROP
```

### TLS Everywhere

Encrypt all container-to-container communication:

- Use mutual TLS (mTLS) for service-to-service authentication
- Implement service meshes like Istio or Linkerd for transparent encryption
- Configure TLS termination at ingress points

## Privilege Management

Limiting container privileges forms a core layer of defense.

### Non-root Container Users

Create and use non-privileged users:

```dockerfile
FROM ubuntu:20.04

# Install required packages
RUN apt-get update && apt-get install -y curl

# Create non-root user
RUN useradd -m appuser

# Set working directory
WORKDIR /home/appuser

# Switch to non-root user
USER appuser

# Command executed when container starts
CMD ["curl", "--version"]
```

### Capability Restriction

Limit Linux capabilities to only those required:

```yaml
# docker-compose.yml with capability restrictions
services:
  app:
    image: myapp:latest
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE
```

### Read-only Filesystem

Prevent runtime filesystem modifications:

```yaml
# docker-compose.yml with read-only filesystem
services:
  app:
    image: myapp:latest
    read_only: true
    volumes:
      - /tmp
      - /var/run
```

## Docker Security Implementation

A comprehensive Docker security implementation integrates multiple protective layers.

### Secure Docker Configuration

Base configuration settings:

```json
// /etc/docker/daemon.json
{
  "live-restore": true,
  "userland-proxy": false,
  "no-new-privileges": true,
  "userns-remap": "default",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

### Container Security Scanning

Implement automated vulnerability scanning:

```yaml
# GitHub Action for scanning Docker images
name: Docker Image Scan

on:
  push:
    branches: [ main ]

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Build image
        run: docker build -t myapp:${{ github.sha }} .
        
      - name: Scan image
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: myapp:${{ github.sha }}
          format: 'table'
          exit-code: '1'
          severity: 'CRITICAL,HIGH'
```

### Runtime Protection

Implement runtime security controls:

1. **Seccomp profiles**: Restrict available system calls
2. **AppArmor/SELinux**: Mandatory access controls
3. **Container health monitoring**: Detect anomalous behavior
4. **Audit logging**: Record security-relevant events

### Infrastructure Protection Layer

Implement broader infrastructure security:

```yaml
# Docker-compose with security configurations
version: '3.8'

services:
  web:
    image: webapp:latest
    security_opt:
      - no-new-privileges:true
      - seccomp:seccomp-profile.json
      - apparmor:webapp-profile
    read_only: true
    tmpfs:
      - /tmp:size=100M
    networks:
      - frontend
    deploy:
      resources:
        limits:
          cpus: '0.50'
          memory: 256M
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/healthz"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

---

[<- Back: DevSecOps Implementation](./03-devsecops-implementation.md) | [Next: Continuous Testing ->](./05-continuous-testing.md)