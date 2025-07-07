# 02a. Prometheus and Grafana 📈

[<- Back to Monitoring](./02-Monitoring.md) | [Next Sub-Topic: Cloud Monitoring ->](./02b-Cloud-Monitoring-Solutions.md)

## Overview

Prometheus and Grafana form the backbone of modern monitoring infrastructure. Prometheus excels at metrics collection and storage with its pull-based architecture, while Grafana provides powerful visualization and alerting capabilities. This combination offers a complete, scalable monitoring solution that's become the industry standard for observability.

## Key Concepts

### Prometheus Architecture

Prometheus is a pull-based monitoring system that scrapes metrics from configured targets:

```yaml
# prometheus.yml configuration
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
  
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['localhost:9100']
  
  - job_name: 'application'
    static_configs:
      - targets: ['app:8080']
```

### PromQL (Prometheus Query Language)

PromQL enables powerful metric queries and aggregations:

```promql
# CPU usage percentage
100 - (avg(irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# HTTP request rate
rate(http_requests_total[5m])

# 95th percentile response time
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
```

### Grafana Data Sources

Grafana connects to multiple data sources including Prometheus:

```json
{
  "name": "Prometheus",
  "type": "prometheus",
  "url": "http://prometheus:9090",
  "access": "proxy",
  "basicAuth": false
}
```

## Implementation Patterns

### Pattern 1: Docker Compose Stack

Complete monitoring stack with Prometheus, Grafana, and Node Exporter:

```yaml
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=200h'
      - '--web.enable-lifecycle'

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning
    depends_on:
      - prometheus

  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    ports:
      - "9100:9100"
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.rootfs=/rootfs'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'

volumes:
  prometheus_data:
  grafana_data:
```

**When to use this pattern:**
- Development environments
- Small-scale production deployments
- Quick prototyping and testing

### Pattern 2: Kubernetes Deployment

Production-ready Kubernetes deployment with Helm:

```bash
# Add Prometheus community Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install kube-prometheus-stack
helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set grafana.adminPassword=admin \
  --set prometheus.prometheusSpec.retention=30d
```

```yaml
# Custom values.yaml for production
grafana:
  persistence:
    enabled: true
    size: 10Gi
  ingress:
    enabled: true
    hosts:
      - grafana.yourdomain.com

prometheus:
  prometheusSpec:
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: fast-ssd
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 50Gi
```

**When to use this pattern:**
- Production Kubernetes environments
- Enterprise-scale monitoring
- Integration with Kubernetes-native services

## Common Challenges and Solutions

### Challenge 1: High Cardinality Metrics

Problem: Too many unique label combinations causing memory issues and slow queries.

**Solution:**

```yaml
# Limit scrape targets and configure metric relabeling
scrape_configs:
  - job_name: 'application'
    scrape_interval: 30s
    metric_relabel_configs:
      # Drop high-cardinality metrics
      - source_labels: [__name__]
        regex: 'http_requests_total_by_user_id'
        action: drop
      
      # Limit label values
      - source_labels: [path]
        regex: '/api/users/[0-9]+'
        target_label: path
        replacement: '/api/users/*'
```

### Challenge 2: Grafana Dashboard Standardization

Problem: Inconsistent dashboards across teams leading to confusion and maintenance overhead.

**Solution:**

```json
{
  "dashboard": {
    "title": "Application Metrics Template",
    "templating": {
      "list": [
        {
          "name": "service",
          "type": "query",
          "query": "label_values(up, job)",
          "refresh": 1
        }
      ]
    },
    "panels": [
      {
        "title": "Request Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(http_requests_total{job=\"$service\"}[5m])"
          }
        ]
      }
    ]
  }
}
```

```bash
# Provision dashboards automatically
mkdir -p grafana/provisioning/dashboards
cat > grafana/provisioning/dashboards/dashboard.yml << EOF
apiVersion: 1
providers:
  - name: 'default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    options:
      path: /etc/grafana/provisioning/dashboards
EOF
```

## Practical Example

Complete application monitoring setup with custom metrics:

```python
# Flask application with Prometheus metrics
from flask import Flask
from prometheus_client import Counter, Histogram, generate_latest
import time

app = Flask(__name__)

# Define metrics
REQUEST_COUNT = Counter('http_requests_total', 'Total HTTP requests', ['method', 'endpoint'])
REQUEST_DURATION = Histogram('http_request_duration_seconds', 'HTTP request duration')

@app.before_request
def before_request():
    request.start_time = time.time()

@app.after_request
def after_request(response):
    request_duration = time.time() - request.start_time
    REQUEST_COUNT.labels(method=request.method, endpoint=request.endpoint).inc()
    REQUEST_DURATION.observe(request_duration)
    return response

@app.route('/metrics')
def metrics():
    return generate_latest()

@app.route('/api/health')
def health():
    return {'status': 'healthy'}

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
```

```dockerfile
# Dockerfile for the monitored application
FROM python:3.9-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY app.py .
EXPOSE 8080

CMD ["python", "app.py"]
```

```yaml
# Complete docker-compose.yml with application
version: '3.8'

services:
  app:
    build: .
    ports:
      - "8080:8080"
    
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    
  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - ./grafana/provisioning:/etc/grafana/provisioning
```

```yaml
# prometheus.yml targeting the application
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'application'
    static_configs:
      - targets: ['app:8080']
    metrics_path: '/metrics'
    scrape_interval: 10s
```

## Summary

Key implementation points for Prometheus and Grafana:

1. **Prometheus excels at metrics collection** through its pull-based architecture and powerful PromQL query language
2. **Grafana provides visualization layer** with rich dashboards, alerting, and multi-datasource support
3. **Docker Compose offers rapid deployment** for development and small-scale production environments

## Next Steps

Explore cloud-native monitoring solutions that build upon these concepts, including managed Prometheus services and advanced alerting strategies in distributed environments.

---

[<- Back to Monitoring](./02-Monitoring.md) | [Next Sub-Topic: Cloud Monitoring ->](./02b-Cloud-Monitoring-Solutions.md)