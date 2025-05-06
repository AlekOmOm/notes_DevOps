# 3. DevSecOps Implementation 📦

[<- Back: Security Fundamentals](./02-security-fundamentals.md) | [Next: Docker Security ->](./04-docker-security.md)

---
- [3a - Security Testing Types](./03a-security-testing-types.md)
- [3b - CI/CD Integration](./03b-cicd-integration.md)
- [3c - Security Gates](./03c-security-gates.md)
---

## Table of Contents

- [DevSecOps Models](#devsecops-models)
- [Security Testing Types](#security-testing-types)
- [Security Gates in CI/CD](#security-gates-in-cicd)
- [Vulnerability Management](#vulnerability-management)
- [Implementation Tools](#implementation-tools)
- [Practical Implementation Patterns](#practical-implementation-patterns)

## DevSecOps Models

DevSecOps implementation follows systematic models that integrate security throughout the development lifecycle.

### Figure 8 Model

The DevSecOps Figure 8 Model represents the continuous flow of security activities across development and operations:

```
    ┌─────────┐     ┌─────────┐
    │  Plan   │     │ Monitor │
    └────┬────┘     └────┬────┘
         │               │
    ┌────▼────┐     ┌────▼────┐
    │  Code   │     │ Operate │
    └────┬────┘     └────┬────┘
         │               │
┌────────▼────────┐     │
│ Continuous      │     │
│ Integration     │     │
└────────┬────────┘     │
         │              │
┌────────▼────────┐     │
│ Continuous      │     │
│ Delivery        │     │
└────────┬────────┘     │
         │              │
    ┌────▼────┐     ┌───▼────┐
    │ Deploy  │────►│ Release│
    └─────────┘     └────────┘
```

At each stage, specific security activities are integrated:

1. **Plan**: Threat modeling, security requirements, risk assessment
2. **Code**: Secure coding guidelines, peer reviews, pre-commit hooks
3. **CI**: SAST, dependency scanning, container scanning
4. **CD**: DAST, compliance checks, infrastructure scanning
5. **Deploy**: Security verification, configuration validation
6. **Release**: Security sign-off, vulnerability validation
7. **Operate**: Runtime protection, behavioral monitoring
8. **Monitor**: Security incident detection, compliance monitoring

### Maturity Model

DevSecOps implementation typically progresses through distinct maturity levels:

| Maturity Level | Characteristics | Key Activities |
|----------------|-----------------|----------------|
| **Initial** | Ad-hoc security, primarily manual | Basic vulnerability scanning, security requirements |
| **Managed** | Some automation, defined processes | SAST integration, dependency scanning |
| **Defined** | Security integrated throughout SDLC | Automated security gates, compliance validation |
| **Quantitatively Managed** | Metrics-driven security | Risk quantification, security dashboards |
| **Optimizing** | Continuous improvement | Self-healing systems, automated remediation |

## Security Testing Types

DevSecOps relies on complementary security testing approaches to identify vulnerabilities at different stages.

### Static Application Security Testing (SAST)

SAST analyzes application source code, bytecode, or binaries for security vulnerabilities without executing the application.

**Key characteristics**:
- Analyzes from the "inside out"
- Detects vulnerabilities early in development
- Provides precise location information
- Language and framework-specific

**Common implementations**:
```yaml
# Example GitHub Action for SAST with SonarQube
name: SAST Analysis

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  sonarqube:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
        with:
          fetch-depth: 0
      
      - name: SonarQube Scan
        uses: SonarSource/sonarqube-scan-action@master
        env:
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
          SONAR_HOST_URL: ${{ secrets.SONAR_HOST_URL }}
```

**Typical findings**:
- SQL injection vulnerabilities
- Cross-site scripting (XSS)
- Insecure cryptographic implementations
- Hardcoded credentials

### Dynamic Application Security Testing (DAST)

DAST tests running applications by simulating attacks from malicious actors.

**Key characteristics**:
- Analyzes from the "outside in"
- Identifies runtime vulnerabilities
- Framework and language agnostic
- Finds issues in deployment configuration

**Common implementations**:
```yaml
# Example GitHub Action for DAST with OWASP ZAP
name: DAST Analysis

on:
  workflow_run:
    workflows: ["Deploy to Test"]
    types:
      - completed

jobs:
  zap_scan:
    runs-on: ubuntu-latest
    steps:
      - name: ZAP Scan
        uses: zaproxy/action-full-scan@v0.4.0
        with:
          target: 'https://test-env.example.com'
          rules_file_name: '.zap/rules.tsv'
          cmd_options: '-a'
```

**Typical findings**:
- Session management flaws
- Authentication vulnerabilities
- Server misconfiguration
- Input validation issues

### Software Composition Analysis (SCA)

SCA identifies vulnerabilities in third-party components and libraries.

**Key characteristics**:
- Analyzes dependencies and packages
- Detects known vulnerabilities via CVE databases
- Identifies license compliance issues
- Minimal false positives

**Common implementations**:
```yaml
# Example GitHub Action for SCA with Dependabot
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10
    
  - package-ecosystem: "docker"
    directory: "/"
    schedule:
      interval: "weekly"
```

**Typical findings**:
- Known CVEs in dependencies
- Outdated libraries
- License conflicts
- Supply chain risks

### Infrastructure as Code (IaC) Scanning

IaC scanning identifies security misconfigurations in infrastructure definitions.

**Key characteristics**:
- Analyzes infrastructure code (Terraform, CloudFormation, etc.)
- Identifies misconfigurations before deployment
- Enforces security best practices
- Validates compliance with policies

**Common implementations**:
```yaml
# Example GitHub Action for IaC scanning with Checkov
name: IaC Security Scan

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  checkov:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Run Checkov
        uses: bridgecrewio/checkov-action@master
        with:
          directory: terraform/
          framework: terraform
```

**Typical findings**:
- Unencrypted data stores
- Overly permissive network rules
- Missing authentication
- Insecure default configurations

## Security Gates in CI/CD

DevSecOps implements security gates throughout the CI/CD pipeline to enforce security standards.

### Pre-commit Gates

Applied before code enters the shared repository:

```bash
#!/bin/sh
# .git/hooks/pre-commit

# Run security linters
security_lint_output=$(security_linter)
if [ $? -ne 0 ]; then
  echo "Security linting failed:"
  echo "$security_lint_output"
  exit 1
fi

# Check for secrets
secrets_scan_output=$(secrets_scanner)
if [ $? -ne 0 ]; then
  echo "Secrets detected in commit:"
  echo "$secrets_scan_output"
  exit 1
fi

exit 0
```

### Pre-merge Gates

Applied before code is merged into protected branches:

```yaml
# Branch protection rules in GitHub
name: Security Checks

on:
  pull_request:
    branches: [ main, release/* ]

jobs:
  security_scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Run security scans
        run: |
          run_sast_scan
          check_dependencies
          validate_secrets_scanning
      
      - name: Security policy check
        run: policy_compliance_check
```

### Pre-deployment Gates

Applied before deploying to environments:

```yaml
# Deployment pipeline with security gates
stages:
  - build
  - test
  - security_scan
  - deploy_staging
  - integration_test
  - security_verification
  - deploy_production

security_scan:
  stage: security_scan
  script:
    - run_sast_scan
    - scan_dependencies
    - check_container_security
  artifacts:
    reports:
      security: security-report.json

security_verification:
  stage: security_verification
  script:
    - run_dast_scan
    - verify_compliance
    - perform_penetration_test
  when: manual
  allow_failure: false
```

### Post-deployment Gates

Applied after deployment to environments:

```yaml
# Post-deployment security verification
post_deployment_check:
  stage: post_deploy
  script:
    - run_security_smoke_tests
    - verify_configuration
    - monitor_security_events
  after_script:
    - generate_security_report
  artifacts:
    reports:
      security: post-deploy-security.json
```

## Vulnerability Management

Effective DevSecOps implementation requires systematic vulnerability management.

### Vulnerability Lifecycle

1. **Identification**: Discover vulnerabilities through scanning
2. **Assessment**: Evaluate severity and risk
3. **Remediation**: Fix vulnerabilities based on priority
4. **Verification**: Confirm successful remediation
5. **Monitoring**: Continuous assessment for regression

### Risk-based Prioritization

Prioritize vulnerabilities based on multiple factors:

```javascript
// Pseudo-code for vulnerability prioritization
function calculateRiskScore(vulnerability) {
  const severityScore = mapCVSS(vulnerability.cvssScore);
  const assetCriticality = getAssetCriticality(vulnerability.affectedAsset);
  const exploitability = assessExploitability(vulnerability);
  const mitigatingControls = evaluateControls(vulnerability.affectedAsset);
  
  return (severityScore * 0.4) + 
         (assetCriticality * 0.3) + 
         (exploitability * 0.2) - 
         (mitigatingControls * 0.1);
}

function prioritizeVulnerabilities(vulnerabilities) {
  return vulnerabilities
    .map(v => ({ ...v, riskScore: calculateRiskScore(v) }))
    .sort((a, b) => b.riskScore - a.riskScore);
}
```

### Automated Remediation

Implement automated fixes for common vulnerabilities:

```yaml
# Automatic dependency updates with Dependabot
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "daily"
    allow:
      - dependency-type: "production"
    open-pull-requests-limit: 10
    versioning-strategy: auto
    assignees:
      - "security-team"
    labels:
      - "security"
      - "dependencies"
```

## Implementation Tools

DevSecOps implementation leverages various specialized tools.

### SAST Tools

- **SonarQube**: Multi-language code quality and security scanner
- **Checkmarx**: Enterprise-grade static code analysis
- **ESLint/Security**: JavaScript-specific security rules
- **Bandit**: Python-specific security scanner

### DAST Tools

- **OWASP ZAP**: Open-source web application security scanner
- **Burp Suite**: Comprehensive web vulnerability scanner
- **Nikto**: Web server scanner
- **SQLmap**: SQL injection detection and exploitation

### SCA Tools

- **Dependabot**: Automated dependency updates
- **Snyk**: Dependency vulnerability and license scanning
- **OWASP Dependency-Check**: Open-source component analyzer
- **WhiteSource**: Open source security and compliance management

### Container Security Tools

- **Trivy**: Container vulnerability scanner
- **Clair**: Container static analysis
- **Anchore**: Container security policy enforcement
- **Docker Bench Security**: Docker host and container assessment

## Practical Implementation Patterns

DevSecOps implementation follows systematic patterns for integration.

### Integration with Existing CI/CD

Integrate security tools into existing pipelines:

```yaml
# GitLab CI with security stages
stages:
  - build
  - test
  - security
  - deploy

security:
  stage: security
  parallel:
    matrix:
      - SCAN_TYPE: ["sast", "dast", "dependency", "container"]
  script:
    - if [ "$SCAN_TYPE" == "sast" ]; then run_sast_scan; fi
    - if [ "$SCAN_TYPE" == "dast" ]; then run_dast_scan; fi
    - if [ "$SCAN_TYPE" == "dependency" ]; then run_dependency_scan; fi
    - if [ "$SCAN_TYPE" == "container" ]; then run_container_scan; fi
  artifacts:
    reports:
      security: gl-$SCAN_TYPE-report.json
```

### Policy as Code

Define security policies as code for automated enforcement:

```yaml
# Open Policy Agent (OPA) policy for Kubernetes
package kubernetes.admission

deny[msg] {
  input.request.kind.kind == "Pod"
  container := input.request.object.spec.containers[_]
  not container.securityContext.runAsNonRoot
  
  msg := sprintf("Container %v must run as non-root", [container.name])
}

deny[msg] {
  input.request.kind.kind == "Pod"
  container := input.request.object.spec.containers[_]
  container.securityContext.privileged
  
  msg := sprintf("Container %v may not run as privileged", [container.name])
}
```

### Security Monitoring

Implement continuous security monitoring:

```yaml
# Prometheus alerting rules for security events
groups:
- name: SecurityAlerts
  rules:
  - alert: UnauthorizedAccessAttempt
    expr: rate(auth_failures_total[5m]) > 10
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "High rate of authentication failures"
      description: "Instance {{ $labels.instance }} has a high rate of auth failures."
      
  - alert: SuspiciousNetworkActivity
    expr: rate(suspicious_network_events[5m]) > 5
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "Suspicious network activity detected"
      description: "Instance {{ $labels.instance }} has suspicious network activity."
```

### Security Metrics Dashboard

Create dashboards to visualize security posture:

```yaml
# Grafana dashboard configuration (partial)
panels:
  - title: "Vulnerability Trend"
    type: "graph"
    datasource: "Prometheus"
    targets:
      - expr: "sum(vulnerabilities_by_severity) by (severity)"
        legendFormat: "{{severity}}"
        
  - title: "Security Scan Status"
    type: "stat"
    datasource: "Prometheus"
    targets:
      - expr: "sum(security_scan_status{status='failed'})"
        legendFormat: "Failed Scans"
        
  - title: "Mean Time to Remediate"
    type: "gauge"
    datasource: "Prometheus"
    targets:
      - expr: "avg(vulnerability_remediation_time_days)"
```

---

[<- Back: Security Fundamentals](./02-security-fundamentals.md) | [Next: Docker Security ->](./04-docker-security.md)