# 8. Terraform: GitHub Provider 🔗

[<- Back: Terraform: Limitations and Problems](./07-terraform-limitations-problems.md) | [Main Note](./README.md)

## Table of Contents

- [Overview of the GitHub Provider](#overview-of-the-github-provider)
- [Prerequisites](#prerequisites)
- [Setting Up the GitHub Provider](#setting-up-the-github-provider)
- [Managing GitHub Resources](#managing-github-resources)
- [Creating a Complete GitHub Configuration](#creating-a-complete-github-configuration)
- [Limitations and Considerations](#limitations-and-considerations)

## Overview of the GitHub Provider

The GitHub provider for Terraform allows you to manage GitHub resources as code. This enables you to:

- Create and manage repositories
- Configure branch protection rules
- Manage teams and memberships
- Set up repository files and webhooks
- Define project settings

Using the GitHub provider, you can codify your GitHub infrastructure, ensuring consistent configuration and enabling automation of GitHub resource management.

## Prerequisites

Before using the GitHub Provider, you need:

1. **Personal Access Token (PAT)**: Create a token with the following scopes:
   - `repo` (for repository management)
   - `admin:org` (which implicitly contains `admin:read`)

   This is different from the Read/Write permissions token used for GitHub Packages.

2. **GitHub Organization**: You need an organization to work with team management features. 
   - This can only be created through the GitHub UI.
   - You can use your personal account for repository-only operations.

## Setting Up the GitHub Provider

### Variables Configuration

Create a `variables.tf` file to define the required inputs:

```hcl
variable "github_token" {
  type        = string
  description = "GitHub Personal Access Token"
  sensitive   = true
}

variable "github_org" {
  type        = string
  description = "GitHub Organization name"
}

variable "team_members" {
  type        = list(string)
  description = "List of GitHub usernames to add to team"
}
```

### Secret Values

Create a `terraform.tfvars` file (which should not be committed to version control):

```hcl
github_token = "ghp_your_token_here"
github_org   = "your-organization-name"
team_members = ["your_github_username"]
```

### Provider Configuration

In your `main.tf`, configure the GitHub provider:

```hcl
provider "github" {
  owner = var.github_org
  token = var.github_token
}
```

## Managing GitHub Resources

The GitHub provider supports many resource types. Here are some of the most common:

### Repositories

```hcl
resource "github_repository" "example" {
  name               = "example-repo"
  description        = "My example repository"
  visibility         = "public"  # or "private"
  
  has_issues         = true
  has_projects       = true
  has_wiki           = true
  
  auto_init          = true  # Initialize with a README
  gitignore_template = "Node"
  license_template   = "mit"
}
```

### Branch Protection

```hcl
resource "github_branch_protection" "main" {
  repository_id = github_repository.example.node_id
  pattern       = "main"
  
  required_pull_request_reviews {
    required_approving_review_count = 1
    dismiss_stale_reviews           = true
  }
  
  enforce_admins = true
}
```

### Teams

```hcl
resource "github_team" "developers" {
  name        = "Developers"
  description = "Development team"
  privacy     = "closed"  # or "secret"
}

resource "github_team_membership" "developer_membership" {
  team_id  = github_team.developers.id
  username = "some-developer"
  role     = "member"  # or "maintainer"
}

resource "github_team_repository" "team_repo" {
  team_id    = github_team.developers.id
  repository = github_repository.example.name
  permission = "push"  # "pull", "push", "maintain", "triage", "admin"
}
```

### Repository Files

```hcl
resource "github_repository_file" "readme" {
  repository          = github_repository.example.name
  file                = "README.md"
  content             = "# Example Repository\n\nManaged by Terraform."
  commit_message      = "Add README"
  commit_author       = "Terraform"
  commit_email        = "terraform@example.com"
  overwrite_on_create = true
}
```

## Creating a Complete GitHub Configuration

Let's put everything together for a complete GitHub infrastructure:

```hcl
provider "github" {
  owner = var.github_org
  token = var.github_token
}

resource "github_repository" "repo" {
  name               = "terraform_provisioned_repo"
  description        = "Provisioned via Terraform"
  visibility         = "public"
  has_issues         = true
  has_projects       = true
  has_wiki           = true
  auto_init          = false
  license_template   = "mit"
  gitignore_template = "Python"
}

resource "github_branch_default" "default" {
  repository = github_repository.repo.name
  branch     = "main"
}

resource "github_repository_file" "readme" {
  repository          = github_repository.repo.name
  file                = "README.md"
  content             = "# Terraform Provisioned Repo \n\nThis repository was provisioned using Terraform."
  commit_message      = "Initial commit"
  overwrite_on_create = true
  branch              = "main"
}

resource "github_repository_file" "github_dir_placeholder" {
  repository          = github_repository.repo.name
  file                = ".github/.keep"
  content             = "This has been provisioned by Terraform"
  commit_message      = "Create .github directory"
  overwrite_on_create = true
  depends_on          = [github_repository_file.readme]
  branch              = "main"
}

resource "github_branch_protection" "main" {
  repository_id = github_repository.repo.node_id
  pattern       = "main"

  required_pull_request_reviews {
    required_approving_review_count = 1
    dismiss_stale_reviews           = false
    require_code_owner_reviews      = false
  }

  enforce_admins = false
}

resource "github_team" "example_team" {
  name        = "core-devs"
  description = "Core developers team"
  privacy     = "closed"
}

resource "github_team_membership" "members" {
  for_each = toset(var.team_members)
  team_id  = github_team.example_team.id
  username = each.value
  role     = "maintainer"

  depends_on = [github_team.example_team]
}
```

### Provisioning the Resources

Use the standard Terraform workflow:

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

After applying, verify that:
1. The team exists in your GitHub organization
2. The repository exists with the specified configuration
3. Branch protection rules have been applied correctly

## Limitations and Considerations

### Destruction Limitations

When using `terraform destroy`, you'll encounter this error with repositories:

```
Error: DELETE https://api.github.com/repos/org-name/repo-name: 403 Must have admin rights to Repository. []
```

This is not a permissions issue but a GitHub limitation. GitHub does not allow API-based deletion of repositories for safety reasons. You'll need to delete repositories manually through the UI.

### Other Considerations

1. **Rate Limiting**: GitHub's API has rate limits that may affect large-scale operations

2. **Token Security**: Ensure your GitHub token is kept secure and not committed to version control

3. **Organizational Policies**: Some GitHub organizational policies may override Terraform-defined settings

4. **Workflows**: GitHub Actions workflows need to be defined separately or using the `github_repository_file` resource

### Best Practices

1. **Progressive Implementation**: Start with a small subset of repositories before applying to your entire organization

2. **Separate State Files**: Use separate state files for different GitHub organizations

3. **CI/CD Integration**: Consider using CI/CD pipelines to apply GitHub configuration changes

4. **Documentation**: Document the GitHub resources managed by Terraform vs. those managed manually

---

[<- Back: Terraform: Limitations and Problems](./07-terraform-limitations-problems.md) | [Main Note](./README.md)