# 6A. Terraform in CI/CD Pipelines 🔄

[<- Back to Main Topic](./06-terraform-hands-on.md) | [Next Sub-Topic: Terraform: Limitations and Problems ->](./07-terraform-limitations-problems.md)

## Overview

This sub-note explores how Terraform can be integrated into CI/CD pipelines for automated infrastructure provisioning. While the educational Azure environment has limitations preventing full implementation, understanding the principles is valuable for real-world applications.

## Key Concepts

### CI/CD for Infrastructure

Continuous Integration and Continuous Deployment for infrastructure follows the same principles as application CI/CD:

1. **Version Control**: Infrastructure code is stored in a repository
2. **Automated Testing**: Infrastructure configurations are validated
3. **Automated Deployment**: Changes are applied automatically
4. **Feedback Loops**: Results are reported back to developers

### The Ideal Terraform CI/CD Flow

```
Code Change → Validate → Plan → Approval → Apply → Verification
```

1. **Code Change**: Developer commits Terraform changes
2. **Validate**: Syntax and formatting are automatically checked
3. **Plan**: A plan is generated to show what would change
4. **Approval**: Optional human review of the plan
5. **Apply**: Changes are applied to the infrastructure
6. **Verification**: Tests confirm the infrastructure works as expected

## Implementation Patterns

### Pattern 1: GitHub Actions

A typical GitHub Actions workflow for Terraform might look like this:

```yaml
name: "Terraform"

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  terraform:
    name: "Terraform"
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout
        uses: actions/checkout@v3
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        
      - name: Terraform Init
        run: terraform init
        
      - name: Terraform Format
        run: terraform fmt -check
        
      - name: Terraform Validate
        run: terraform validate
      
      - name: Terraform Plan
        run: terraform plan
        if: github.event_name == 'pull_request'
        
      - name: Terraform Apply
        run: terraform apply -auto-approve
        if: github.ref == 'refs/heads/main' && github.event_name == 'push'
```

**When to use this pattern:**
- For standard Terraform deployments
- When you want to automate the entire workflow
- For projects with a mature infrastructure codebase

### Pattern 2: Terraform Cloud Integration

For teams using Terraform Cloud, the workflow can be simplified:

```yaml
name: "Terraform Cloud"

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  terraform:
    name: "Terraform"
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout
        uses: actions/checkout@v3
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          cli_config_credentials_token: ${{ secrets.TF_API_TOKEN }}
        
      - name: Terraform Init
        run: terraform init
        
      - name: Terraform Format
        run: terraform fmt -check
        
      - name: Terraform Validate
        run: terraform validate
      
      # Terraform Cloud handles plan and apply phases
```

**When to use this pattern:**
- When using Terraform Cloud for state management
- For larger teams with more complex workflows
- When you want to leverage Terraform Cloud's policy checks and other features

## Common Challenges and Solutions

### Challenge 1: Authentication to Cloud Providers

In CI/CD environments, you need automated, non-interactive authentication.

**Solution:**

For Azure, configure a service principal and store credentials as secrets:

```yaml
- name: Azure Login
  uses: azure/login@v1
  with:
    creds: ${{ secrets.AZURE_CREDENTIALS }}

- name: Terraform Init
  run: terraform init
  env:
    ARM_CLIENT_ID: ${{ secrets.ARM_CLIENT_ID }}
    ARM_CLIENT_SECRET: ${{ secrets.ARM_CLIENT_SECRET }}
    ARM_SUBSCRIPTION_ID: ${{ secrets.ARM_SUBSCRIPTION_ID }}
    ARM_TENANT_ID: ${{ secrets.ARM_TENANT_ID }}
```

### Challenge 2: State Management

Managing Terraform state securely in CI/CD environments is critical.

**Solution:**

Configure a remote backend in your Terraform configuration:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate"
    storage_account_name = "tfstate023912"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"
  }
}
```

In your CI/CD pipeline, ensure the appropriate access credentials are available.

## Practical Example

A complete example of Terraform in an Azure DevOps pipeline:

```yaml
trigger:
  branches:
    include:
      - main

pool:
  vmImage: 'ubuntu-latest'

variables:
  - group: terraform-variables

stages:
  - stage: Validate
    jobs:
      - job: ValidateTerraform
        steps:
          - task: TerraformInstaller@0
            inputs:
              terraformVersion: '1.0.0'
          
          - task: TerraformTaskV3@3
            inputs:
              provider: 'azurerm'
              command: 'init'
              backendType: 'azurerm'
              backendServiceArm: 'azure-service-connection'
              backendAzureRmResourceGroupName: 'tfstate'
              backendAzureRmStorageAccountName: 'tfstate023912'
              backendAzureRmContainerName: 'tfstate'
              backendAzureRmKey: 'dev.terraform.tfstate'
          
          - task: TerraformTaskV3@3
            inputs:
              provider: 'azurerm'
              command: 'validate'
          
  - stage: Plan
    dependsOn: Validate
    jobs:
      - job: PlanTerraform
        steps:
          - task: TerraformInstaller@0
            inputs:
              terraformVersion: '1.0.0'
          
          - task: TerraformTaskV3@3
            inputs:
              provider: 'azurerm'
              command: 'init'
              backendType: 'azurerm'
              backendServiceArm: 'azure-service-connection'
              backendAzureRmResourceGroupName: 'tfstate'
              backendAzureRmStorageAccountName: 'tfstate023912'
              backendAzureRmContainerName: 'tfstate'
              backendAzureRmKey: 'dev.terraform.tfstate'
          
          - task: TerraformTaskV3@3
            inputs:
              provider: 'azurerm'
              command: 'plan'
              environmentServiceName: 'azure-service-connection'
              publishPlanResults: 'terraform-plan'
  
  - stage: Apply
    dependsOn: Plan
    jobs:
      - deployment: ApplyTerraform
        environment: 'dev'
        strategy:
          runOnce:
            deploy:
              steps:
                - task: TerraformInstaller@0
                  inputs:
                    terraformVersion: '1.0.0'
                
                - task: TerraformTaskV3@3
                  inputs:
                    provider: 'azurerm'
                    command: 'init'
                    backendType: 'azurerm'
                    backendServiceArm: 'azure-service-connection'
                    backendAzureRmResourceGroupName: 'tfstate'
                    backendAzureRmStorageAccountName: 'tfstate023912'
                    backendAzureRmContainerName: 'tfstate'
                    backendAzureRmKey: 'dev.terraform.tfstate'
                
                - task: TerraformTaskV3@3
                  inputs:
                    provider: 'azurerm'
                    command: 'apply'
                    environmentServiceName: 'azure-service-connection'
```

## Summary

While we can't fully implement these solutions in our educational environment due to service principal limitations, these patterns represent industry best practices for integrating Terraform into CI/CD pipelines:

1. Terraform CI/CD pipelines automate infrastructure deployment, reducing manual errors
2. Remote state backends are essential for team collaboration and pipeline integration
3. Secure handling of credentials is critical for cloud provider authentication
4. Implementing approval gates provides control over infrastructure changes
5. Different pipeline patterns suit different organizational needs and maturity levels

## Next Steps

As you progress beyond educational environments to production settings:

1. Implement service principal authentication for non-interactive workflows
2. Set up remote state backends for team collaboration
3. Integrate policy-as-code tools like Checkov or TFLint
4. Establish environment promotion patterns (dev -> test -> prod)
5. Implement testing frameworks for infrastructure validation

---

[<- Back to Main Topic](./06-terraform-hands-on.md) | [Next Sub-Topic: Terraform: Limitations and Problems ->](./07-terraform-limitations-problems.md)