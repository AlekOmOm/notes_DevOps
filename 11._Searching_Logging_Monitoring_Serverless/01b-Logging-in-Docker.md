# 01b. Logging in Docker 🐳

[<- Back to Main Topic](./01-Logging.md) | [<- Previous: Logging Implementation](./01a-Logging-Implementation.md)

## Overview

Docker containers introduce unique challenges for logging due to their ephemeral nature. This note covers best practices for collecting, managing, and centralizing logs from containerized applications.

## Key Concepts

### Docker Logging Basics

Docker captures anything written to stdout and stderr from the container's main process:

```bash
# View logs for a container
docker logs <container_id>

# Follow logs in real-time
docker logs -f <container_id>

# Show timestamps
docker logs -t <container_id>

# Show only the last n lines
docker logs --tail=100 <container_id>
```

By default, these logs are stored in JSON files under `/var/lib/docker/containers/` on the host, but they're lost when a container is removed.

### Logging Drivers

Docker supports various logging drivers that determine where logs are sent:

```yaml
# docker-compose.yml example with syslog driver
version: '3'
services:
  app:
    image: my-app
    logging:
      driver: syslog
      options:
        syslog-address: "udp://logserver:514"
        tag: "{{.Name}}"
```

Common logging drivers include:

| Driver | Description | Use Case |
|--------|-------------|----------|
| `json-file` | Stores logs as JSON files | Default, for local development |
| `local` | Improved local logging driver | Enhanced local logging with lower overhead |
| `syslog` | Sends logs to syslog server | Central logging infrastructure |
| `journald` | Sends logs to journald | Systems using systemd |
| `fluentd` | Sends logs to Fluentd | Advanced log processing |
| `awslogs` | Sends logs to Amazon CloudWatch | AWS deployments |
| `splunk` | Sends logs to Splunk | Enterprise Splunk users |
| `gelf` | Sends logs to Graylog | Graylog deployments |

## Implementation Patterns

### Pattern 1: Application-Aware Logging

Configure your application to write structured logs to stdout/stderr:

```javascript
// Node.js example with Winston
const winston = require('winston');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console()
  ]
});

// Usage
logger.info('Container started', { service: 'api', version: '1.2.0' });
```

**When to use this pattern:**
- For most containerized applications
- When you want to leverage Docker's built-in logging
- When you need structured logs

### Pattern 2: Side-Car Container for Logging

Deploy a separate container dedicated to log collection alongside your application:

```yaml
# docker-compose.yml for sidecar logging pattern
version: '3'
services:
  app:
    image: my-app
    volumes:
      - app-logs:/var/log/app
    # Application writes logs to files in /var/log/app

  log-collector:
    image: fluent/fluentd
    volumes:
      - app-logs:/var/log/app:ro
      - ./fluentd/conf:/fluentd/etc
    ports:
      - "24224:24224"
    # Collects logs from /var/log/app and forwards them

volumes:
  app-logs:
```

**When to use this pattern:**
- When your application can't easily be modified to log to stdout
- For applications that manage their own log files
- When you need more control over log processing

## Common Challenges and Solutions

### Challenge 1: Log Storage and Rotation

Unmanaged logs can consume significant disk space.

**Solution:**

```yaml
# Configure Docker daemon with log rotation
# /etc/docker/daemon.json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

For individual containers or services:

```yaml
# docker-compose.yml
version: '3'
services:
  app:
    image: my-app
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"
```

### Challenge 2: Centralized Logging

Collecting logs from multiple containers across multiple hosts.

**Solution:**

Using the Elastic Stack (ELK):

```yaml
# docker-compose.yml for ELK stack
version: '3'
services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.14.0
    environment:
      - discovery.type=single-node
    ports:
      - "9200:9200"
    volumes:
      - elasticsearch-data:/usr/share/elasticsearch/data

  logstash:
    image: docker.elastic.co/logstash/logstash:7.14.0
    volumes:
      - ./logstash/pipeline:/usr/share/logstash/pipeline
    ports:
      - "5044:5044"
    depends_on:
      - elasticsearch

  kibana:
    image: docker.elastic.co/kibana/kibana:7.14.0
    ports:
      - "5601:5601"
    depends_on:
      - elasticsearch

  filebeat:
    image: docker.elastic.co/beats/filebeat:7.14.0
    user: root
    volumes:
      - ./filebeat/filebeat.yml:/usr/share/filebeat/filebeat.yml:ro
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
    depends_on:
      - logstash

volumes:
  elasticsearch-data:
```

Filebeat configuration (`filebeat.yml`):

```yaml
filebeat.inputs:
- type: container
  paths:
    - /var/lib/docker/containers/*/*.log
  processors:
    - add_docker_metadata:
        host: "unix:///var/run/docker.sock"

output.logstash:
  hosts: ["logstash:5044"]
```

## Practical Example

A complete Docker Compose setup with effective logging:

```yaml
# docker-compose.yml
version: '3.8'

services:
  # Application service
  api:
    build: ./api
    container_name: api
    restart: unless-stopped
    environment:
      - NODE_ENV=production
      - LOG_LEVEL=info
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
        tag: "{{.Name}}"
    networks:
      - app-network

  # Database service
  db:
    image: postgres:13
    container_name: db
    restart: unless-stopped
    environment:
      - POSTGRES_PASSWORD=secret
      - POSTGRES_USER=app
      - POSTGRES_DB=appdata
    volumes:
      - db-data:/var/lib/postgresql/data
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
        tag: "{{.Name}}"
    networks:
      - app-network

  # Log forwarding service
  fluentd:
    image: fluent/fluentd:v1.13
    container_name: fluentd
    volumes:
      - ./fluentd/conf:/fluentd/etc
    ports:
      - "24224:24224"
    networks:
      - app-network
      - logging-network

  # Elasticsearch for log storage
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.14.0
    container_name: elasticsearch
    environment:
      - discovery.type=single-node
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    volumes:
      - elastic-data:/usr/share/elasticsearch/data
    networks:
      - logging-network

  # Kibana for log visualization
  kibana:
    image: docker.elastic.co/kibana/kibana:7.14.0
    container_name: kibana
    ports:
      - "5601:5601"
    depends_on:
      - elasticsearch
    networks:
      - logging-network

networks:
  app-network:
  logging-network:

volumes:
  db-data:
  elastic-data:
```

Fluentd configuration (`fluentd/conf/fluent.conf`):

```
<source>
  @type forward
  port 24224
  bind 0.0.0.0
</source>

<filter docker.**>
  @type parser
  key_name log
  reserve_data true
  <parse>
    @type json
    json_parser json
  </parse>
</filter>

<match docker.**>
  @type elasticsearch
  host elasticsearch
  port 9200
  logstash_format true
  logstash_prefix docker
  include_tag_key true
  tag_key @log_name
  flush_interval 5s
</match>
```

Docker log driver setup for services:

```yaml
# Add to each service in docker-compose.yml to use fluentd
logging:
  driver: fluentd
  options:
    fluentd-address: localhost:24224
    tag: docker.{{.Name}}
```

## Summary

1. Docker captures stdout/stderr by default but logs are lost when containers are removed
2. Logging drivers direct container logs to various destinations
3. Log rotation is essential to prevent disk space issues
4. Centralized logging solutions like ELK stack provide visibility across containers
5. Structure your logs in JSON format for better searchability and analysis

## Next Steps

With logging systems in place for both applications and containers, explore monitoring systems which provide real-time visibility into system health, complementing the discrete event data captured by logs.

---

[<- Back to Main Topic](./01-Logging.md) | [<- Previous: Logging Implementation](./01a-Logging-Implementation.md)
