# Infrastructure as Code Learning Notes 🏗️

[Start Learning ->](./01-overview-of-iac.md)

This collection of notes provides a comprehensive guide to Infrastructure as Code (IaC), with a focus on Terraform and declarative approaches to infrastructure management.

## Learning Path

1. **[Overview of IaC](./01-overview-of-iac.md)** 🌟
   - What is Infrastructure as Code?
   - Key concepts and terminology
   - Relation to DevOps principles

2. **[Why Infrastructure as Code](./02-why-infrastructure-as-code.md)** 📦
   - Benefits and advantages
   - Ways to work with cloud services
   - The disaster scenario
   - X as Code concept

3. **[IaC and Configuration Management Tools](./03-iac-configuration-management-tools.md)** ⚙️
   - Popular IaC tools
   - Cloud provider specific vs. agnostic tools
   - Configuration management vs. provisioning
   - Terraform overview

4. **[Imperative vs Declarative Approaches](./04-imperative-vs-declarative.md)** 🔄
   - Conceptual differences
   - Pros and cons
   - Implementation examples
   - Idempotency in infrastructure
   
   [Managing State in Declarative Systems](./04a-managing-state.md)

5. **[Terraform: Getting Started](./05-terraform-get-started.md)** 🚀
   - Installation and setup
   - Basic workflow
   - Key commands
   - File structure

6. **[Terraform: Hands-On](./06-terraform-hands-on.md)** 💻
   - Workspaces
   - Creating resources in Azure
   - Variables and outputs
   - Remote provisioning
   
   [Terraform in CI/CD Pipelines](./06a-terraform-azure-pipeline.md)

7. **[Terraform: Limitations and Problems](./07-terraform-limitations-problems.md)** 🛡️
   - State file challenges
   - State drift issues
   - Solutions for state management
   - Feature limitations

8. **[Terraform: GitHub Provider](./08-terraform-github-provider.md)** 🔗
   - Setting up the GitHub provider
   - Managing repositories as code
   - Team and permission management
   - Practical examples

---

## DevOps Principle

Infrastructure as Code: **Repeatable, Reliable, Redeployable**

This principle emphasizes that infrastructure should be:
- Version-controlled like application code
- Automatically provisioned with minimal human intervention
- Consistently deployable across different environments

---

_(These notes are designed for DevOps engineers and developers interested in automating infrastructure provisioning and management through code.)_