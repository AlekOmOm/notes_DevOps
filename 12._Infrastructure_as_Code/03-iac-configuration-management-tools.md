# 3. IaC and Configuration Management Tools ⚙️

[<- Back: Why Infrastructure as Code](./02-why-infrastructure-as-code.md) | [Next: Imperative vs Declarative Approaches ->](./04-imperative-vs-declarative.md)

## Table of Contents

- [Defining IaC](#defining-iac)
- [Configuration Management Tools](#configuration-management-tools)
- [Cloud Provider Specific IaC Tools](#cloud-provider-specific-iac-tools)
- [Cloud Provider Agnostic IaC Tools](#cloud-provider-agnostic-iac-tools)
- [Why Terraform?](#why-terraform)

## Defining IaC

There are two common ways to define Infrastructure as Code:

1. **Broad Definition**: Any tool that uses code to define anything related to infrastructure
   - Includes configuration management tools that operate after provisioning

2. **Narrow Definition**: Tools specifically for provisioning cloud resources
   - Focuses on the creation and management of infrastructure components

While both definitions are technically correct, in practice, the term IaC is often used in the narrower sense. However, some tools like Ansible blur these boundaries by handling both provisioning and configuration.

## Configuration Management Tools

Configuration management tools focus on installing software, configuring systems, and maintaining desired state on existing infrastructure. The top 5 include:

| Tool | Description |
|------|-------------|
| **Ansible** | Automates cloud provisioning, configuration management, and application deployments |
| **Puppet** | Manages infrastructure as code, providing automation and deployment capabilities |
| **Chef** | Turns infrastructure into code to automate server deployment and configuration |
| **Salt** | Offers powerful automation, orchestration, and configuration management in one |
| **CFEngine** | Provides automated configuration and maintenance of large-scale IT systems |

### Benefits of Configuration Management Tools

- **Automation**: Reduces manual effort and errors
- **Time Saving**: Eliminates repetitive tasks
- **Consistency**: Ensures uniform configurations
- **Scalability**: Manages large-scale infrastructure efficiently
- **Version Control**: Tracks changes via versioning
- **Security**: Enforces security policies and standards
- **Recovery**: Aids in quick disaster recovery
- **Collaboration**: Enhances DevOps collaboration

## Cloud Provider Specific IaC Tools

Each major cloud provider offers its own native IaC tools:

### Azure
- **Bicep**: A domain-specific language for declaratively deploying Azure resources
- **Azure Resource Manager (ARM) Templates**: JSON-based templates for Azure resource deployment

### AWS
- **AWS CloudFormation**: Service for deploying and managing AWS resources using JSON/YAML templates

### Google Cloud
- **Google Cloud Deployment Manager**: Service for managing cloud resources using declarative templates

These tools offer deep integration with their respective platforms but can lead to vendor lock-in.

## Cloud Provider Agnostic IaC Tools

For organizations using multiple cloud providers or wanting to avoid vendor lock-in, several tools offer cross-platform support:

- **Pulumi**: Infrastructure as code in general-purpose languages (JavaScript, Python, etc.)
- **Serverless Framework**: Declarative YAML for defining services across cloud providers
- **Ansible**: Automates cloud provisioning and configuration management with YAML
- **Terraform**: Defines cloud and on-premises resources with a consistent workflow

## Why Terraform?

Terraform has become the industry standard for infrastructure as code for several key reasons:

1. **Dependency Management**: Maintains a dependency graph to determine the correct order for creating or destroying resources

2. **State Management**: Tracks the current state of infrastructure through its state file

3. **Version Control Integration**: Works well with Git and other VCS tools

4. **Declarative Approach**: Define what you want, not how to achieve it

5. **Provider Ecosystem**: Supports multiple cloud providers and services

6. **Community Support**: Large user base and extensive documentation

7. **Open Source**: Core functionality is open source, with enterprise features available

### Terraform Alternative

It's worth noting that OpenTofu is an open-source fork of Terraform that emerged due to licensing changes. It offers compatibility with Terraform while maintaining an open-source model:

- https://opentofu.org/

---

[<- Back: Why Infrastructure as Code](./02-why-infrastructure-as-code.md) | [Next: Imperative vs Declarative Approaches ->](./04-imperative-vs-declarative.md)