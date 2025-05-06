# 6. GitHub Security Features 🔒

[<- Back: Continuous Testing](./05-continuous-testing.md) | [Next: Security Monitoring ->](./07-security-monitoring.md)

---
- [6a - Dependency Management](./06a-dependency-management.md)
- [6b - Actions Security](./06b-actions-security.md)
- [6c - Code Scanning](./06c-code-scanning.md)
---

## Table of Contents

- [GitHub Security Overview](#github-security-overview)
- [Dependency Security](#dependency-security)
- [GitHub Actions Security](#github-actions-security)
- [Code Scanning and Analysis](#code-scanning-and-analysis)
- [Secret Scanning](#secret-scanning)
- [Security Policies](#security-policies)
- [Implementation Best Practices](#implementation-best-practices)

## GitHub Security Overview

GitHub provides an integrated security platform that addresses multiple aspects of the software development lifecycle. As a central component in modern DevSecOps implementations, GitHub's security features enable automated vulnerability detection, dependency management, and policy enforcement.

### Security Feature Integration

GitHub's security features integrate directly into the development workflow:

1. **Pre-coding**: Security policies, branch protection
2. **During development**: Code scanning, dependency analysis
3. **Pre-merge**: Status checks, vulnerability alerts
4. **Post-merge**: Continuous scanning, automated updates

### Security Dashboard

The GitHub Security Dashboard provides centralized visibility into security issues:

- **Vulnerability aggregation**: Consolidates findings across repositories
- **Risk prioritization**: Categorizes vulnerabilities by severity
- **Remediation tracking**: Monitors fix status and progress
- **Compliance reporting**: Generates audit-ready reports

## Dependency Security

Dependency management represents one of the most critical security concerns in modern development.

### Dependabot

Dependabot automates dependency updates to address vulnerabilities:

#### Dependabot Alerts

Automated vulnerability notifications:

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    # Security updates always enabled by default
```

Dependabot alerts:
- Notify about vulnerable dependencies
- Link to CVE details and remediation options
- Track status of vulnerability fixes

#### Dependabot Security Updates

Automatic pull requests for security-related updates:

```yaml
# .github/dependabot.yml with security updates
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    # Customizations for security updates
    open-pull-requests-limit: 10
    assignees:
      - "security-team"
    labels:
      - "security"
      - "dependencies"
```

Configuration options:
- PR assignment to security teams
- Customized labels for tracking
- Review requirements via branch protection

#### Dependabot Version Updates

Scheduled dependency updates for freshness:

```yaml
# .github/dependabot.yml with version updates
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
      time: "09:00"
      timezone: "UTC"
    allow:
      - dependency-type: "direct"
    ignore:
      - dependency-name: "express"
        versions: ["4.x.x"]
    commit-message:
      prefix: "deps"
      include: "scope"
```

Advanced configuration:
- Specific update schedules
- Dependency filtering
- Version constraints
- Commit message formatting

### Software Bill of Materials (SBOM)

GitHub facilitates the creation of Software Bill of Materials through dependency tracking:

- **Dependency graphs**: Automatic analysis of dependencies
- **Ecosystem support**: Coverage for npm, PyPI, RubyGems, Maven, etc.
- **Export capabilities**: Generation of SBOM in standard formats
- **Supply chain visibility**: Tracking of transitive dependencies

## GitHub Actions Security

GitHub Actions introduces both powerful automation capabilities and security considerations.

### Actions Security Risks

GitHub Actions can introduce specific security risks:

1. **Supply chain attacks**: Malicious third-party actions
2. **Secret exposure**: Leaking sensitive credentials
3. **Resource abuse**: Cryptomining or DoS attacks
4. **Privilege escalation**: Unauthorized repository access

### Secure Actions Implementation

Implement GitHub Actions securely using the following practices:

#### First-party Actions

Prioritize official GitHub-maintained actions:

```yaml
# Example using official actions
name: CI Pipeline

on:
  push:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '16'
      - uses: actions/cache@v3
        with:
          path: ~/.npm
          key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
```

#### Action Hash Pinning

Pin actions to specific commit hashes rather than tags:

```yaml
# Bad practice (tag reference)
- uses: actions/checkout@v3

# Better practice (hash pinning)
- uses: actions/checkout@8e5e7e5ab8b370d6c329ec480221332ada57f0ab
```

Hash pinning provides:
- Immutability guarantees
- Protection against tag tampering
- Auditability of exact code executed

#### OIDC for Cloud Authentication

Use OpenID Connect for secure cloud provider authentication:

```yaml
# Example of OIDC with AWS
name: AWS Deployment

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: actions/checkout@v3
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v1
        with:
          role-to-assume: arn:aws:iam::123456789012:role/github-actions
          aws-region: us-east-1
```

OIDC benefits:
- Eliminates long-lived credentials
- Provides short-term, scoped tokens
- Enables fine-grained permissions

#### Secrets Protection

Securely manage secrets within Actions:

```yaml
# Example with protected secrets
name: Deployment

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      # Avoid exposing secrets
      - name: Deploy application
        run: |
          echo "Deploying to production environment"
          ./deploy.sh
        env:
          API_TOKEN: ${{ secrets.API_TOKEN }}
```

Secret protection techniques:
- Never log secrets directly
- Encrypt secrets at rest
- Set appropriate secret scopes
- Rotate secrets regularly

#### Avoiding Command Injection

Prevent command injection through proper input handling:

```yaml
# Vulnerable to injection
- name: Process user input (unsafe)
  run: echo "Processing ${{ github.event.issue.title }}"

# Protected against injection
- name: Process user input (safe)
  run: |
    INPUT="${{ github.event.issue.title }}"
    echo "Processing input safely"
```

Command injection protections:
- Avoid using user inputs directly in commands
- Validate and sanitize inputs
- Use intermediate variables

## Code Scanning and Analysis

GitHub provides integrated code scanning capabilities to identify security vulnerabilities and code quality issues.

### CodeQL

CodeQL provides powerful semantic code analysis:

```yaml
# .github/workflows/codeql-analysis.yml
name: "CodeQL Analysis"

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
  schedule:
    - cron: '0 0 * * 0'

jobs:
  analyze:
    name: Analyze
    runs-on: ubuntu-latest
    permissions:
      security-events: write
      
    steps:
    - name: Checkout repository
      uses: actions/checkout@v3
      
    - name: Initialize CodeQL
      uses: github/codeql-action/init@v2
      with:
        languages: [ 'javascript', 'python' ]
        
    - name: Perform CodeQL Analysis
      uses: github/codeql-action/analyze@v2
```

CodeQL capabilities:
- Language-aware analysis
- Variant analysis for vulnerability patterns
- Query customization for specific checks
- Security and quality rule libraries

### Third-party Scanning Integration

Integrate additional scanning tools through the GitHub Marketplace:

```yaml
# Example with SonarCloud integration
name: SonarCloud Scan

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  sonarcloud:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0
          
      - name: SonarCloud Scan
        uses: SonarSource/sonarcloud-github-action@master
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
```

Integration benefits:
- Specialized analysis capabilities
- Compliance with specific standards
- Alternative detection techniques
- Additional security coverage

### Security Issue Management

Manage identified security issues through GitHub's interface:

- **Security advisories**: Creation of private CVEs
- **Issue tracking**: Assignment and prioritization
- **Vulnerability database**: Integration with public databases
- **Fix tracking**: Monitoring of remediation progress

## Secret Scanning

GitHub's secret scanning identifies and protects sensitive information in repositories.

### Automatic Secret Detection

GitHub automatically detects common credential patterns:

```yaml
# .github/workflows/secret-scanning.yml
name: Secret Scanning Alerting

on:
  push:
    branches: [ main ]

jobs:
  secret-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Run custom secret scanning
        run: |
          npm install -g detect-secrets
          detect-secrets scan > secret-report.json
          
      - name: Upload scan results
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: secret-report.json
```

Scanning capabilities:
- API key pattern recognition
- Token format detection
- Entropy analysis for random strings
- Partner integrations for automated revocation

### Custom Pattern Registration

Define custom patterns for organization-specific secrets:

```json
// Example custom secret pattern definition
{
  "name": "Company API Token",
  "pattern": "company_api_[a-zA-Z0-9]{32}",
  "severity": "critical",
  "description": "Company internal API authentication token"
}
```

Pattern customization:
- Regular expression definitions
- Severity categorization
- False positive handling
- Alert routing configuration

## Security Policies

GitHub supports formal security policies for repositories and organizations.

### Security Policy Files

Define repository security policies with SECURITY.md:

```markdown
# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 5.1.x   | :white_check_mark: |
| 5.0.x   | :x:                |
| 4.0.x   | :white_check_mark: |
| < 4.0   | :x:                |

## Reporting a Vulnerability

Please report security vulnerabilities to security@example.com.

Our security team will acknowledge receipt within 24 hours and provide a detailed response within 48 hours, including:
- Confirmation of the vulnerability
- Planned timeline for a fix
- Potential workarounds

We request responsible disclosure and will coordinate with you on publication timing.
```

Policy components:
- Supported version definitions
- Vulnerability reporting process
- Response SLA commitments
- Disclosure coordination guidelines

### Branch Protection Rules

Implement branch protections for security enforcement:

```
Branch: main
☑ Require pull request reviews before merging
  ☑ Require review from Code Owners
  ☑ Dismiss stale pull request approvals when new commits are pushed
  ☑ Require approval of the most recent reviewable push
☑ Require status checks to pass before merging
  ☑ Require branches to be up to date before merging
  ☑ Status checks:
    ☑ CodeQL Analysis
    ☑ SonarCloud Analysis
    ☑ Security Scan
☑ Require signed commits
☑ Include administrators
```

Protection benefits:
- Mandatory code review
- Status check enforcement
- Signed commit requirements
- Force push prevention

## Implementation Best Practices

Implement GitHub security features following established best practices.

### Gradual Feature Adoption

Implement security features incrementally:

1. **Phase 1**: Enable Dependabot alerts
2. **Phase 2**: Activate Dependabot security updates
3. **Phase 3**: Implement secret scanning
4. **Phase 4**: Deploy code scanning
5. **Phase 5**: Enforce branch protections

### Security Feature Automation

Automate security feature enforcement:

```yaml
# .github/workflows/security-enforcement.yml
name: Security Enforcement

on:
  repository_dispatch:
    types: [security-scan]
  schedule:
    - cron: '0 0 * * *'

jobs:
  enforce_security:
    runs-on: ubuntu-latest
    steps:
      - name: Verify security features
        run: |
          gh api repos/${{ github.repository }}/vulnerability-alerts
          gh api repos/${{ github.repository }}/code-scanning/alerts
          gh api repos/${{ github.repository }}/secret-scanning/alerts
        env:
          GH_TOKEN: ${{ secrets.GH_TOKEN }}
```

### Security Metrics

Track security metrics for continuous improvement:

```yaml
# .github/workflows/security-metrics.yml
name: Security Metrics Collection

on:
  schedule:
    - cron: '0 0 * * 0'

jobs:
  collect_metrics:
    runs-on: ubuntu-latest
    steps:
      - name: Collect vulnerability metrics
        run: |
          OPEN_ALERTS=$(gh api repos/${{ github.repository }}/vulnerability-alerts --jq '.[] | select(.state=="open") | .number' | wc -l)
          FIXED_ALERTS=$(gh api repos/${{ github.repository }}/vulnerability-alerts --jq '.[] | select(.state=="fixed") | .number' | wc -l)
          echo "::set-output name=open_alerts::$OPEN_ALERTS"
          echo "::set-output name=fixed_alerts::$FIXED_ALERTS"
        env:
          GH_TOKEN: ${{ secrets.GH_TOKEN }}
```

Key metrics to track:
- Mean time to remediation (MTTR)
- Vulnerability density per LOC
- Fix rate over time
- False positive ratio

### Developer Education

Implement developer security education:

1. **Documentation**: Maintain comprehensive security guidelines
2. **Training**: Conduct regular security awareness sessions
3. **Feedback**: Provide contextual security guidance in code reviews
4. **Champions**: Designate security champions within development teams

---

[<- Back: Continuous Testing](./05-continuous-testing.md) | [Next: Security Monitoring ->](./07-security-monitoring.md)