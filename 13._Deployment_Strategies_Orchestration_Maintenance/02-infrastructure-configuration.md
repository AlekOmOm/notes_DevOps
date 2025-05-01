# 2. Infrastructure and Configuration Management 📦

[<- Back: Overview](./01-overview.md) | [Next: Deployment Strategies ->](./03-deployment-strategies.md)

## Table of Contents

- [Introduction](#introduction)
- [Platform Engineering](#platform-engineering)
- [Cloud Development Environments](#cloud-development-environments)
- [Cattle vs. Pets Philosophy](#cattle-vs-pets-philosophy)
- [Managing Configuration Drift](#managing-configuration-drift)
- [Immutable Infrastructure](#immutable-infrastructure)
- [Implementation Patterns](#implementation-patterns)
- [Summary](#summary)

## Introduction

Infrastructure and configuration management represent the foundation of modern DevOps practices. These disciplines focus on how we provision, configure, and maintain the underlying compute resources that run our applications. By applying software engineering principles to infrastructure management, we can achieve greater consistency, reliability, and efficiency in our operations.

## Platform Engineering

### What is Platform Engineering?

Platform engineering is the discipline of designing and building toolchains and workflows that enable self-service capabilities for software engineering organizations. The goal is to create a developer platform that makes it easy for development teams to provision environments, deploy applications, and access operational capabilities without requiring specialized infrastructure knowledge.

### Key Benefits

- **Reduced Operational Bottlenecks**: Developers can provision resources without waiting for operations teams
- **Standardization**: Enforces consistent environments and practices
- **Improved Developer Experience**: Reduces friction in the development workflow
- **Faster Time to Market**: Accelerates the path from code to production

### Implementation Examples

```javascript
// Example Terraform code for a self-service platform
// that creates standardized environments
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "${var.environment}-vpc"
    Environment = var.environment
  }
}

// Define environment modules that can be instantiated on demand
module "development_environment" {
  source = "./modules/standard_environment"
  environment = "development"
  instance_size = "t3.medium"
  auto_scaling_min = 2
  auto_scaling_max = 4
}
```

## Cloud Development Environments

Cloud Development Environments (CDEs) extend platform engineering concepts to the developer's local experience. They provide development environments as code, making it possible to:

- Accelerate onboarding with pre-configured environments
- Maintain consistent tooling across the team
- Keep sensitive information secure by not storing it locally
- Reduce "works on my machine" problems

Popular CDE platforms include:
- [Gitpod](https://www.gitpod.io/)
- [Coder](https://coder.com/)
- [GitHub Codespaces](https://github.com/features/codespaces)

## Cattle vs. Pets Philosophy

A fundamental shift in infrastructure management is captured by the "cattle vs. pets" metaphor:

> "In the old way of doing things, we treated our servers like pets: we gave them names, and when they got sick, we nursed them back to health. In the new way, servers are treated like cattle: they're numbered, and when they get sick, you replace them."
> 
> — Bill Baker, Microsoft

### Pets Approach (Traditional)

- Servers are unique, manually configured
- Downtime is disruptive and requires careful recovery
- Scale by making individual servers more powerful (vertical scaling)
- Updates are applied in-place

### Cattle Approach (Modern)

- Servers are identical, automatically provisioned
- Failure is expected and handled through replacement
- Scale by adding more servers (horizontal scaling)
- Updates are done by replacing servers entirely

This perspective change underpins many modern operational practices, particularly immutable infrastructure.

## Managing Configuration Drift

Configuration drift occurs when systems that should be identical gradually become different due to manual changes, inconsistent updates, or environmental factors. This inconsistency leads to unpredictable behavior and makes systems harder to maintain.

### The Challenge

- Manual changes don't get recorded in version control
- Different team members make different changes
- Emergency fixes bypass normal processes
- Over time, no one knows the exact state of each system

### Solution: Infrastructure as Code

Infrastructure as Code (IaC) addresses configuration drift by:

1. **Defining infrastructure through code** stored in version control
2. **Automating provisioning** so it's consistent and repeatable
3. **Making infrastructure declarative** by specifying desired state rather than steps
4. **Enabling testing** of infrastructure changes before deployment

```javascript
// Example Infrastructure as Code using Terraform
provider "aws" {
  region = "us-west-2"
}

resource "aws_instance" "web" {
  count = 3
  ami = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  
  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup python -m SimpleHTTPServer 80 &
              EOF
              
  tags = {
    Name = "web-server-${count.index}"
  }
}
```

## Immutable Infrastructure

Immutable infrastructure takes the cattle philosophy to its logical conclusion: instead of updating servers in place, you replace them entirely when changes are needed.

### Key Principles

- **No in-place updates**: Servers are never modified after deployment
- **Complete rebuilds**: Any change requires creating new servers from updated images
- **Version-controlled builds**: Server configurations are built through automated, version-controlled processes
- **Atomic deployments**: All changes happen at once, not incrementally

### Benefits

- **Elimination of configuration drift**: Every server matches its definition exactly
- **Simplified rollback**: Just revert to previous server images
- **Consistent environments**: Development, testing, and production use identical builds
- **Improved security**: Regular rebuilds apply security patches consistently

### Implementation Example

Traditional (Mutable) vs. Immutable Approach to Updating Nginx:

**Mutable Approach:**
```bash
# SSH into the server
ssh user@server

# Install the update
sudo apt update
sudo apt upgrade nginx

# Restart the service
sudo systemctl restart nginx
```

**Immutable Approach:**
```bash
# Build a new image with updated Nginx
packer build -var 'nginx_version=1.20.1' nginx-template.json

# Deploy new servers with the updated image
terraform apply -var 'image_id=ami-0abc123'

# Direct traffic to new servers, then decommission old ones
```

## Implementation Patterns

### Pattern 1: Baking Complete Images

Create complete machine images that include the operating system, runtime, and application.

```javascript
// Example using Packer to build an AMI
{
  "builders": [{
    "type": "amazon-ebs",
    "region": "us-west-2",
    "source_ami": "ami-0c55b159cbfafe1f0",
    "instance_type": "t2.micro",
    "ssh_username": "ubuntu",
    "ami_name": "web-server-{{timestamp}}"
  }],
  "provisioners": [{
    "type": "shell",
    "inline": [
      "sudo apt-get update",
      "sudo apt-get install -y nginx",
      "sudo systemctl enable nginx"
    ]
  }]
}
```

**When to use this pattern:**
- When deployment speed is critical
- For applications with complex dependencies
- When you want to minimize runtime configuration

### Pattern 2: Configuration Injection

Build minimal base images and inject configuration at runtime.

```javascript
// Example using user_data in AWS
resource "aws_instance" "web" {
  ami = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  
  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y nginx
              echo "server_name ${var.domain_name};" >> /etc/nginx/conf.d/default.conf
              systemctl restart nginx
              EOF
}
```

**When to use this pattern:**
- When you need flexibility across environments
- For simpler applications with fewer dependencies
- When build time needs to be minimized

### Pattern 3: Containerization

Package applications and their dependencies as containers that run consistently anywhere.

```dockerfile
# Example Dockerfile
FROM nginx:1.21
COPY ./config/nginx.conf /etc/nginx/conf.d/default.conf
COPY ./html /usr/share/nginx/html
EXPOSE 80
```

**When to use this pattern:**
- For microservices architectures
- When you need consistent environments across development and production
- When you want to leverage container orchestration tools

## Summary

Infrastructure and configuration management have evolved from manual processes to programmable, automated approaches that emphasize consistency, reproducibility, and immutability. Key takeaways include:

1. Platform engineering and CDEs provide self-service capabilities that empower development teams.

2. The shift from treating servers as "pets" to "cattle" reflects a fundamental change in how we approach infrastructure.

3. Configuration drift represents a significant challenge that can be addressed through Infrastructure as Code.

4. Immutable infrastructure provides a powerful pattern for ensuring consistency and simplifying operations.

5. Various implementation patterns (image baking, configuration injection, containerization) offer flexibility based on specific requirements.

These approaches form the foundation for the deployment strategies and orchestration techniques we'll explore in subsequent sections.

---

[<- Back: Overview](./01-overview.md) | [Next: Deployment Strategies ->](./03-deployment-strategies.md)
