# 4. Continuous Deployment ⚡

[<- Back: Postmortem Practices](./03-postmortem.md) | [Next: Reverse Proxies ->](./05-reverse-proxies.md)

## Table of Contents

- [Motivation: Avoiding Big Bang Deployment](#motivation-avoiding-big-bang-deployment)
- [CI/CD/CD Definitions](#cicdcd-definitions)
- [Deployment Types](#deployment-types)
- [Full Continuous Deployment](#full-continuous-deployment)
- [Quality Gates](#quality-gates)
- [Pipeline Optimization](#pipeline-optimization)
- [Industry Practices](#industry-practices)

## Motivation: Avoiding Big Bang Deployment

**Big Bang Deployment**: Deploying the entire application at once, creating high risk and potential for widespread failures.

Problems with Big Bang approach:
- High blast radius when failures occur
- Difficult to isolate and rollback specific changes
- Requires extensive coordination across teams
- Creates bottlenecks and stress points

**Solution**: Continuous deployment enables frequent, small, low-risk releases.

## CI/CD/CD Definitions

Quick recap of the continuous practices hierarchy:

- **Continuous Integration (CI)**: Automated building and testing of code changes
- **Continuous Delivery (CD)**: Automated deployment to staging/pre-production environments  
- **Continuous Deployment (CD)**: Automated deployment to production environments

## Deployment Types

### Code-on-Server Approaches

1. **Direct Git Pull**
   ```bash
   git pull → python app.py
   git pull → gunicorn app:app  # preferred for production
   ```

2. **Git Pull + Docker Compose**
   ```bash
   git pull → docker-compose up
   ```

### Codebase-Never-Touches-Server Approaches

3. **Server as Runner Agent**
   - GitHub Actions runner on server executes deployment

4. **Image-Based Deployment**
   ```bash
   docker pull <image> → docker run <image>
   ```

5. **Compose with Remote Images**
   ```bash
   docker-compose pull → docker-compose up -d
   ```

## Full Continuous Deployment

### Docker-Compose Build vs. No Building

Consider this docker-compose snippet:
```yaml
services:
  app:
    image: ghcr.io/user/app:latest
    build:
      context: ./backend
      dockerfile: Dockerfile.dev
```

**With Building** (requires codebase):
```bash
docker-compose build
```

**Without Building** (image-only):
```bash
docker-compose pull
docker-compose up -d
```

### Full CD Implementation

**The Goal**: True continuous deployment with zero manual intervention.

**Full CD Pattern**:
1. `scp docker-compose.yml` onto server
2. `docker-compose pull` 
3. `docker-compose up -d`

**Workflow Components**:
- **Build Phase**: Create and push images to registry
- **Deploy Phase**: 
  - Transfer configuration (docker-compose.yml)
  - Pull latest images
  - Deploy with zero downtime

**Benefits of scp vs git pull**:
- **scp**: Simple file transfer, no repository dependencies
- **git pull**: Requires git repository access, more complex

## Quality Gates

### Definition
Quality gates secure deployment quality and reduce runtime by running validation before deployment.

### Single Job Quality Gates

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - name: Security Testing
      run: echo "Running security tests..."
      if: success()  # default behavior
      
    - name: Deploy to Production
      run: echo "Deploying..."
```

### Multiple Job Quality Gates

```yaml
jobs:
  security-tests:
    runs-on: ubuntu-latest
    steps:
    - name: Security Testing
      run: echo "Security validation..."

  build-tests:
    runs-on: ubuntu-latest
    steps:
    - name: Build and Test
      run: echo "Build validation..."

  deploy:
    runs-on: ubuntu-latest
    needs: [security-tests, build-tests]
    steps:
    - name: Deploy to Production
      run: echo "Deploying..."
```

### Workflow Dependencies

Run workflow after another workflow completion:
```yaml
on:
  workflow_run:
    workflows: ["Test Workflow"]
    types: [completed]
```

## Pipeline Optimization

### Architecture for Reduced Runtime

Key strategies:
- **Parallel execution** where possible
- **Quality gates** as dependencies, not sequential steps
- **Fail fast** principles
- **Caching** for repeated operations

### Example Optimized Pipeline

```yaml
jobs:
  # Run in parallel
  lint:
    runs-on: ubuntu-latest
    steps: [...]
    
  security:
    runs-on: ubuntu-latest
    steps: [...]
    
  unit-tests:
    runs-on: ubuntu-latest
    steps: [...]
  
  # Deploy only if all gates pass
  deploy:
    needs: [lint, security, unit-tests]
    steps: [...]
```

## Rollback Strategies

**Critical Capability**: Quick rollback across the entire pipeline.

### Rollback Points
- **CI Stage**: Revert commits, rebuild
- **CD Stage**: Redeploy previous version to staging
- **Production**: Blue-green deployment, feature flags, database migrations

### Implementation Patterns
- **Image Tags**: Use semantic versioning for easy rollback
- **Infrastructure as Code**: Version control for infrastructure changes
- **Database Migrations**: Backward-compatible schemas

## Industry Practices

### GitHub (2012-2016)
- Dozens of deployments per day
- Any employee can deploy via Campfire
- Automatic deployment after tests pass
- "Deployment days" completely eliminated

### Amazon (2011)
**Deployment Stats**:
- Mean time between deployments: 11.6 seconds
- Max deployments in single hour: 1,079
- Mean hosts per deployment: 10,000
- Max hosts per deployment: 30,000

**Results**:
- 75% reduction in deployment-triggered outages
- 90% reduction in outage minutes
- ~0.001% deployment failure rate
- Instantaneous automated rollback

### Facebook Evolution

**2012**: 
- One minor update on business days
- One major weekly update (Tuesdays)

**2016+**:
- Quasi-continuous deployment from master
- Tiered rollout to 100% production over hours
- Massive scale operations

## Continuous Deployment Tools

### Commercial Solutions
- **Octopus Deploy**: Enterprise deployment automation
- **DeployBot**: Git-based deployment workflows
- **GitHub Actions**: Integrated CI/CD platform

### Key Features to Evaluate
- Integration with existing toolchain
- Rollback capabilities  
- Multi-environment support
- Monitoring and alerting
- Security and compliance features

---

[<- Back: Postmortem Practices](./03-postmortem.md) | [Next: Reverse Proxies ->](./05-reverse-proxies.md)
