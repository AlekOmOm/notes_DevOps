# 02b. AlertManager 🚨

[<- Back to Prometheus and Grafana](./02a-Prometheus-and-Grafana.md) | [Next Sub-Topic: Cloud Monitoring ->](./02c-Cloud-Monitoring-Solutions.md)

## Overview

AlertManager is Prometheus's companion service that **mediates raw "alerts" into human-grade notifications**. It transforms detection events into actionable, organized, and contextual notifications while preventing alert fatigue through sophisticated routing, grouping, and silencing mechanisms.

The fundamental principle: separate concerns between detection (Prometheus) and notification management (AlertManager).

## Key Concepts

### Alert Processing Pipeline

The conceptual flow from detection to notification:

```
prometheus (evaluates alerting rules) 
    → http push of alert objects (json) 
        → alertmanager pipeline 
            → receivers (email, slack, pagerduty, webhooks…)
```

**Separation of concerns:**
- **Prometheus** ≈ *detect* (rule evaluation, firing conditions)
- **AlertManager** ≈ *decide + deliver* (routing, grouping, silencing, notification)

### Core Vocabulary

| Term | Idea | Why It Matters |
|------|------|----------------|
| **Alert** | Data blob {labels, annotations, startsAt…} | Unit of signal from Prometheus |
| **Receiver** | Notification backend config block | Where messages land (Slack, email, PagerDuty) |
| **Route** | Tree of matchers → receiver | Deterministic dispatch logic |
| **Group** | Set of alerts sharing label-keys | Collapse storm into 1 message |
| **Deduplication** | hash(alert.labels) in memory | Ignore repeats within time window |
| **Inhibition** | *if X firing then mute Y* | Suppress noise during root-cause events |
| **Silence** | Time-boxed matcher set | Planned muting (maintenance windows) |
| **Cluster Mode** | Gossip + memberlist | HA; every instance has full state |

## Implementation Patterns

### Pattern 1: Basic AlertManager Setup

Minimal production-ready configuration:

```yaml
# alertmanager.yml
global:
  resolve_timeout: 5m        # resend "resolved" after 5m
  smtp_smarthost: 'localhost:587'
  smtp_from: 'alerts@company.com'

route:
  group_by: ['cluster', 'alertname']
  group_wait: 30s           # wait to combine fresh alerts
  group_interval: 5m        # how often to send about existing groups
  repeat_interval: 3h       # how often to resend unresolved alerts
  receiver: oncall
  
  routes:
  - match:
      severity: critical
    receiver: pager
    group_wait: 10s
    repeat_interval: 1h
  
  - match:
      team: database
    receiver: dba-team

receivers:
- name: oncall
  slack_configs:
  - channel: "#alerts"
    send_resolved: true
    title: 'Alert: {{ .GroupLabels.alertname }}'
    text: |
      {{ range .Alerts }}
      *Alert:* {{ .Annotations.summary }}
      *Description:* {{ .Annotations.description }}
      *Severity:* {{ .Labels.severity }}
      {{ end }}

- name: pager
  pagerduty_configs:
  - service_key: 'your-pagerduty-service-key'
    description: '{{ .GroupLabels.alertname }} - {{ .CommonAnnotations.summary }}'

- name: dba-team
  email_configs:
  - to: 'dba-team@company.com'
    subject: 'Database Alert: {{ .GroupLabels.alertname }}'
```

**When to use this pattern:**
- Small to medium teams
- Clear severity-based escalation
- Basic notification channels

### Pattern 2: Enterprise Routing with Inhibition

Advanced configuration for complex organizations:

```yaml
# alertmanager.yml - Enterprise setup
global:
  resolve_timeout: 5m

route:
  group_by: ['cluster', 'service']
  group_wait: 20s
  group_interval: 5m
  repeat_interval: 4h
  receiver: default
  
  routes:
  # Critical infrastructure alerts
  - match_re:
      alertname: '(NodeDown|KubernetesNodeNotReady)'
    receiver: infrastructure-team
    group_wait: 10s
    repeat_interval: 30m
    
  # Application alerts during business hours
  - match:
      team: application
    receiver: app-team-business-hours
    active_time_intervals:
    - business-hours
    
  # After hours - page only critical
  - match:
      team: application
      severity: critical
    receiver: app-team-oncall

inhibit_rules:
# If node is down, don't alert on services on that node
- source_match:
    alertname: NodeDown
  target_match:
    alertname: ServiceDown
  equal: ['instance']

# If cluster is down, don't alert on individual services
- source_match:
    alertname: ClusterDown
  target_match_re:
    alertname: '(ServiceDown|HighLatency)'
  equal: ['cluster']

time_intervals:
- name: business-hours
  time_intervals:
  - times:
    - start_time: '09:00'
      end_time: '17:00'
    weekdays: ['monday:friday']
    location: 'Local'

receivers:
- name: default
  slack_configs:
  - channel: "#general-alerts"
    
- name: infrastructure-team
  slack_configs:
  - channel: "#infrastructure"
  pagerduty_configs:
  - service_key: 'infra-service-key'
    
- name: app-team-business-hours
  slack_configs:
  - channel: "#app-team"
  email_configs:
  - to: 'app-team@company.com'
    
- name: app-team-oncall
  pagerduty_configs:
  - service_key: 'app-oncall-key'
```

**When to use this pattern:**
- Large organizations with multiple teams
- Complex escalation policies
- Need for noise reduction through inhibition

## Common Challenges and Solutions

### Challenge 1: Alert Fatigue and Noise

Problem: Too many non-actionable alerts overwhelming the team.

**Solution:**

```yaml
# Implement proper grouping and inhibition
route:
  group_by: ['cluster', 'service', 'alertname']
  group_wait: 2m        # Allow time for related alerts
  group_interval: 10m   # Batch updates
  repeat_interval: 6h   # Don't spam

# Use alert severity levels properly
inhibit_rules:
- source_match:
    severity: critical
  target_match:
    severity: warning
  equal: ['service']    # Critical alerts suppress warnings for same service
```

```yaml
# Prometheus alert rules with proper FOR clauses
groups:
- name: application
  rules:
  - alert: HighErrorRate
    expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.1
    for: 5m             # Wait 5 minutes before firing
    labels:
      severity: warning
      team: application
    annotations:
      summary: "High error rate on {{ $labels.service }}"
      description: "Error rate is {{ $value | humanizePercentage }}"
      runbook_url: "https://wiki.company.com/runbooks/high-error-rate"
```

### Challenge 2: Maintenance Window Management

Problem: Getting alerts during planned maintenance windows.

**Solution:**

```bash
# Create silences programmatically
amtool silence add \
  --alertmanager.url=http://alertmanager:9093 \
  --author="deploy-script" \
  --comment="Deployment maintenance window" \
  --duration=1h \
  service="api-gateway"

# Silence by multiple labels
amtool silence add \
  cluster="production" \
  severity="warning" \
  --duration=30m \
  --comment="Network maintenance"
```

```yaml
# Template for deployment scripts
apiVersion: v1
kind: ConfigMap
metadata:
  name: silence-script
data:
  silence.sh: |
    #!/bin/bash
    DURATION=${1:-1h}
    SERVICE=${2:-all}
    
    amtool silence add \
      --alertmanager.url=$ALERTMANAGER_URL \
      --author="automation" \
      --comment="Automated deployment silence" \
      --duration=$DURATION \
      service="$SERVICE"
```

## Practical Example

Complete setup with Prometheus, AlertManager, and application:

```yaml
# docker-compose.yml - Complete monitoring stack
version: '3.8'

services:
  app:
    build: .
    ports:
      - "8080:8080"
    environment:
      - APP_NAME=demo-app
    
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus:/etc/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--alertmanager.url=http://alertmanager:9093'
    
  alertmanager:
    image: prom/alertmanager:latest
    ports:
      - "9093:9093"
    volumes:
      - ./alertmanager:/etc/alertmanager
    command:
      - '--config.file=/etc/alertmanager/alertmanager.yml'
      - '--cluster.listen-address='
      
  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
```

```yaml
# prometheus/prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

alerting:
  alertmanagers:
  - static_configs:
    - targets: ['alertmanager:9093']

rule_files:
  - "alert_rules.yml"

scrape_configs:
  - job_name: 'app'
    static_configs:
      - targets: ['app:8080']
```

```yaml
# prometheus/alert_rules.yml
groups:
- name: application_alerts
  rules:
  - alert: HighErrorRate
    expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
    for: 2m
    labels:
      severity: warning
      team: backend
    annotations:
      summary: "High error rate detected"
      description: "Error rate is {{ $value | humanizePercentage }} for {{ $labels.job }}"
      
  - alert: ServiceDown
    expr: up == 0
    for: 1m
    labels:
      severity: critical
      team: sre
    annotations:
      summary: "Service {{ $labels.job }} is down"
      description: "{{ $labels.job }} has been down for more than 1 minute"
```

```bash
# amtool examples for management
# List all active alerts
amtool alert query

# List silences
amtool silence query

# Create silence for deployment
amtool silence add \
  --duration=30m \
  --comment="API deployment" \
  job="api"

# Remove silence
amtool silence expire <silence-id>
```

## Processing Pipeline Logic

The AlertManager decision tree for incoming alerts:

```
assume incoming alert A

if A matches an active silence         → drop
else if A inhibited by higher-order B  → drop
else
    if hash(A.labels) already notified → dedup
    else                               → enqueue group
        if group_wait / group_interval passed
            → pick receiver via routing tree
                → render templates
                    → send notification
```

## Summary

AlertManager serves as the intelligent notification layer that transforms Prometheus alerts into actionable notifications:

1. **Separation of concerns** - Prometheus detects, AlertManager decides and delivers
2. **Sophisticated routing** - Tree-based matching with label selectors for precise targeting
3. **Noise reduction** - Grouping, deduplication, and inhibition prevent alert fatigue

## Next Steps

Explore cloud-native monitoring solutions that integrate AlertManager patterns, including managed services and advanced notification strategies for distributed systems.

---

[<- Back to Prometheus and Grafana](./02a-Prometheus-and-Grafana.md) | [Next Sub-Topic: Cloud Monitoring ->](./02c-Cloud-Monitoring-Solutions.md)