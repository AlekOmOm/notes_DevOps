# 04 Software Quality 

## TOC
01. Introduction & DevOps Principles
02. Software Quality Concepts
03. CI/CD/CD Pipeline
04. Linting
05. Branching Strategies
06. CRON Jobs

## Weekly DevOps Principle
- **Collaboration** and **Communication**
- Praxis: Make PRs of a readable size

## Software Quality

### Definition
ISO Standard: "Capability of a software product to satisfy stated and implied needs when used under specified conditions"

### Key Aspects
- Not just code quality - includes documentation and configuration
- Focuses on both functional and non-functional requirements
- Quantifiable through metrics and tools

### Value Stream
- Definition: "End-to-end set of activities which collectively create value for customer"
- Example: PR as DevOps value stream (indirect value creation)
- Balance between immediate customer value and technical excellence

### Software Quality Metrics
- Code Coverage
- Cyclomatic Complexity
- Code Duplication
- Code Smells
- Technical Debt
- Maintainability Index
- Reliability

### Quality Tools
- SonarQube (technical debt measure)
- Code Climate (maintainability index)
- Coverity
- Kiuwan
- Veracode
- Codacy

## Technical Debt

### Types
- Code Debt: Poor code quality, hard to maintain
- Design Debt: Architectural issues
- Infrastructure Debt: Outdated systems/tools
- Testing Debt: Insufficient test coverage
- Documentation Debt: Poor/missing documentation
- Process Debt: Inefficient workflows

### Managing Technical Debt
- Regular code reviews
- Refactoring
- Clean code practices
- Documentation updates
- Automated testing

## CI/CD/CD Pipeline

### Continuous Integration (CI)
- Regular code merging to main branch
- Automated testing
- Early issue detection

### Continuous Delivery (CD)
- Automated artifact creation
- Focus: Docker image creation
- Publishing to container registry

### Continuous Deployment (CD)
- Automated deployment to production
- Server deployment automation
- Running containerized applications

### CI/CD Tools
- Self-hosted:
  - Jenkins
  - Bamboo
  - TeamCity
  - Concourse
  - Azure DevOps Server

- Cloud-based:
  - GitHub Actions
  - GitLab CI
  - CircleCI
  - Travis CI

## Linting

### Purpose
- Static code analysis
- Error detection
- Style enforcement
- Security checking
- Performance optimization

### Implementation
- Local pre-commit hooks
- CI pipeline integration
- IDE integration (e.g., SonarLint)

### Popular Linters by Language
- JavaScript: ESLint, Standard
- Python: Pylint, Black
- Java: Checkstyle
- Rust: Clippy

## Branching Strategies

### Common Approaches
- Feature Branching
- Trunk-based Development
- Release Branching
- Gitflow
- GitHub Flow

### Key Concepts
- Merge vs Rebase
- Pull Request workflows
- Branch protection rules

## CRON Jobs

### Fundamentals
- Time-based job scheduler
- Periodic task automation
- Syntax: minute hour day month weekday

### DevOps Usage
- Automated deployments
- Regular maintenance tasks
- Monitoring and alerts
- Backup scheduling
