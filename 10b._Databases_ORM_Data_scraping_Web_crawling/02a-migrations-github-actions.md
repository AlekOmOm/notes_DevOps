# 2a. Migrations with GitHub Actions 🔄

[<- Back to Migrations](./02-migrations.md) | [Next: Database Schema Version Control ->](./02b-database-schema-version-control.md)

## Table of Contents
- [Why GitHub Actions for Migrations](#why-github-actions-for-migrations)
- [Setting Up Migration Workflows](#setting-up-migration-workflows)
- [Environment Management](#environment-management)
- [Migration Safety Checks](#migration-safety-checks)
- [Rollback Automation](#rollback-automation)
- [Complete Workflow Examples](#complete-workflow-examples)

## Why GitHub Actions for Migrations

GitHub Actions provides an ideal platform for automating database migrations for several reasons:

1. **Integration with Version Control**: Migrations run directly from your versioned code
2. **Environment Separation**: Create distinct workflows for dev, staging, and production
3. **Security**: Secrets management for database credentials
4. **Conditional Execution**: Run migrations only when schema files change
5. **Approval Gates**: Add manual approval steps for production migrations
6. **Audit Trail**: Complete history of when migrations were executed and by whom

## Setting Up Migration Workflows

### Basic Migration Workflow

This example uses Knex.js for migrations in a Node.js application:

```yaml
# .github/workflows/database-migrations.yml
name: Database Migrations

on:
  push:
    branches: [main]
    paths:
      - 'migrations/**'
      - 'knexfile.js'

jobs:
  migrate:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Run migrations
        run: npx knex migrate:latest
        env:
          POSTGRES_HOST: ${{ secrets.DB_HOST }}
          POSTGRES_USER: ${{ secrets.DB_USER }}
          POSTGRES_PASSWORD: ${{ secrets.DB_PASSWORD }}
          POSTGRES_DB: ${{ secrets.DB_NAME }}
```

### Key Components:

- **Trigger Conditions**: Only run when migration files or configuration changes
- **Environment Variables**: Store database credentials as secrets
- **Migration Command**: Run the actual migration tool

## Environment Management

Managing migrations across different environments (dev, staging, production) is a common requirement. GitHub Actions can handle this with environment-specific workflows:

```yaml
name: Database Migrations

on:
  push:
    branches: [main]
    paths:
      - 'migrations/**'
      - 'knexfile.js'

jobs:
  migrate-dev:
    runs-on: ubuntu-latest
    environment: development
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      # ... setup steps ...
      
      - name: Run migrations on development
        run: npx knex migrate:latest --env development
        env:
          POSTGRES_HOST: ${{ secrets.DB_HOST }}
          POSTGRES_USER: ${{ secrets.DB_USER }}
          POSTGRES_PASSWORD: ${{ secrets.DB_PASSWORD }}
          POSTGRES_DB: ${{ secrets.DB_NAME }}
  
  migrate-staging:
    needs: migrate-dev
    runs-on: ubuntu-latest
    environment: staging
    
    steps:
      # ... similar steps for staging ...
  
  migrate-production:
    needs: migrate-staging
    runs-on: ubuntu-latest
    environment: production
    # Add manual approval requirement
    environment:
      name: production
      url: ${{ steps.deploy.outputs.deployment-url }}
    
    steps:
      # ... similar steps for production ...
```

### Environment Configuration:

Set up environments in your GitHub repository settings to:
- Define environment-specific secrets
- Add required reviewers for sensitive environments
- Set protection rules and wait times

## Migration Safety Checks

Before running migrations, especially in production, adding safety checks can prevent potential issues:

```yaml
# ... previous workflow content ...

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      # ... setup steps ...
      
      - name: Validate migrations
        run: |
          # Check for down migrations
          if grep -r -L "expor