# 5. Reverse Proxies with Nginx 🔄

[<- Back: Continuous Deployment](./04-continuous-deployment.md) | [Next: Implementation Patterns ->](./06-implementation-patterns.md)

## Table of Contents

- [Reverse Proxy Fundamentals](#reverse-proxy-fundamentals)
- [Nginx Configuration Basics](#nginx-configuration-basics)
- [Static Content Serving](#static-content-serving)
- [Location Blocks and Routing](#location-blocks-and-routing)
- [Proxy Configuration](#proxy-configuration)
- [Load Balancing Strategies](#load-balancing-strategies)
- [Docker Integration](#docker-integration)

## Reverse Proxy Fundamentals

### What is a Reverse Proxy?

```
       -1.->       -2.-> 
Client       Nginx      Server
       <-4.-       <-3.- 
```

A reverse proxy sits between clients and backend servers, forwarding client requests to appropriate servers and returning responses back to clients.

**Popular Reverse Proxies**: Nginx, Apache, HAProxy, Traefik

### Core Use Cases

#### 1. Load Balancing
**Definition**: Distributing client requests across multiple servers.

**Distribution Strategies**:
- **Round Robin**: Sequential server selection
- **Least Connections**: Route to server with fewest active connections
- **IP Hash**: Route based on client IP hash
- **Random**: Random server selection
- **Weighted Load Balancing**: Assign different weights to servers

#### 2. HTTP Caching
Cache responses to reduce backend load and improve response times.

#### 3. Security
- **Port Protection**: Centralized access control
- **IP Whitelisting**: Control access by IP ranges
- **TLS Termination**: Handle SSL/TLS encryption once at proxy level

## Nginx Configuration Basics

### Basic Nginx Structure

```nginx
events {
    worker_connections 1024;
}

http {
    include mime.types;
    
    server {
        listen 80;
        server_name localhost;
        
        location / {
            root /usr/share/nginx/html;
            index index.html;
        }
    }
}
```

### Syntax Components

**Directives**: Key-value pairs separated by semicolons
```nginx
listen 80;
root /var/www/html;
```

**Contexts**: Blocks containing related directives
```nginx
http {
    # HTTP context directives
    server {
        # Server context directives
    }
}
```

### Running Nginx with Docker

```bash
# Basic run
docker run --rm -it -p 8080:80 nginx

# With custom configuration
docker run --rm -it -p 8080:8080 \
    -v $(pwd)/nginx.conf:/etc/nginx/nginx.conf:ro \
    -v $(pwd)/website:/usr/share/nginx/html:ro \
    nginx
```

## Static Content Serving

### Basic Static Configuration

```nginx
events {}

http {
    include mime.types;
    
    server {
        listen 8080;
        root /usr/share/nginx/html;
        index index.html;
    }
}
```

### MIME Types Configuration

**Problem**: CSS files served as `text/plain` instead of `text/css`

**Manual Solution**:
```nginx
http {
    types {
        text/css            css;
        text/html           html;
        text/javascript     js;
    }
}
```

**Better Solution**: Use built-in MIME types
```nginx
http {
    include mime.types;
    # ... rest of configuration
}
```

## Location Blocks and Routing

### Basic Location Matching

```nginx
server {
    listen 8080;
    root /usr/share/nginx/html;
    
    # Exact path matching
    location /api {
        root /usr/share/nginx/html;
    }
    
    # Alias for different path mapping
    location /docs {
        alias /usr/share/nginx/html/documentation;
    }
}
```

### Regular Expression Locations

```nginx
# Case-insensitive regex matching
location ~* /count/[0-9] {
    try_files /count/count.html /index.html =404;
}

# Try files in order, return 404 if none found
location /dynamic {
    try_files $uri $uri/ /index.html =404;
}
```

### Root vs Alias

**Root**: Appends location to root path
```nginx
location /images {
    root /var/www;  # Serves files from /var/www/images/
}
```

**Alias**: Replaces location with alias path
```nginx
location /images {
    alias /var/www/static;  # Serves files from /var/www/static/
}
```

## Proxy Configuration

### Basic Reverse Proxy Setup

```nginx
server {
    listen 80;
    
    location / {
        proxy_pass http://backend:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### Proxy Headers Explained

- **Host**: Preserves original request's host header
- **X-Real-IP**: Passes client's actual IP address
- **X-Forwarded-For**: Tracks client IP through proxy chain
- **X-Forwarded-Proto**: Maintains original protocol (http/https)

### Multiple Backend Services

```nginx
server {
    listen 80;
    
    location /api/ {
        proxy_pass http://api-server:3000/;
    }
    
    location /auth/ {
        proxy_pass http://auth-server:4000/;
    }
    
    location / {
        proxy_pass http://frontend:8080/;
    }
}
```

## Load Balancing Strategies

### Upstream Configuration

```nginx
upstream backend {
    # Round robin (default)
    server backend1:8080;
    server backend2:8080;
    server backend3:8080;
}

upstream weighted_backend {
    server backend1:8080 weight=3;
    server backend2:8080 weight=2;
    server backend3:8080 weight=1;
}

upstream least_conn_backend {
    least_conn;
    server backend1:8080;
    server backend2:8080;
}

upstream ip_hash_backend {
    ip_hash;
    server backend1:8080;
    server backend2:8080;
}

server {
    location / {
        proxy_pass http://backend;
    }
}
```

### Health Checks and Failover

```nginx
upstream backend {
    server backend1:8080 max_fails=3 fail_timeout=30s;
    server backend2:8080 max_fails=3 fail_timeout=30s;
    server backend3:8080 backup;  # Only used if others fail
}
```

## Docker Integration

### Docker Compose with Nginx

```yaml
version: '3.8'

services:
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    networks:
      - app_network
    depends_on:
      - app1
      - app2

  app1:
    image: myapp:latest
    networks:
      - app_network

  app2:
    image: myapp:latest
    networks:
      - app_network

networks:
  app_network:
    driver: bridge
```

### Docker Network Configuration

```nginx
# nginx.conf for Docker Compose
events {}

http {
    upstream app_backend {
        server app1:8080;
        server app2:8080;
    }
    
    server {
        listen 80;
        
        location / {
            proxy_pass http://app_backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
    }
}
```

## Production Nginx Management

### Without Docker

**Starting Nginx**:
```bash
nginx
```

**Reloading Configuration**:
```bash
nginx -s reload
```

**Stopping Nginx**:
```bash
nginx -s quit      # Graceful stop
nginx -s stop      # Force stop
```

### Configuration Testing

```bash
nginx -t           # Test configuration syntax
nginx -T           # Test and dump configuration
```

## Common Patterns

### SSL Termination

```nginx
server {
    listen 443 ssl;
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location / {
        proxy_pass http://backend;
        # Backend receives HTTP, SSL handled by proxy
    }
}
```

### Microservices Routing

```nginx
server {
    listen 80;
    
    location /user-service/ {
        proxy_pass http://user-service:3001/;
    }
    
    location /order-service/ {
        proxy_pass http://order-service:3002/;
    }
    
    location /payment-service/ {
        proxy_pass http://payment-service:3003/;
    }
    
    # Frontend for all other routes
    location / {
        proxy_pass http://frontend:8080/;
    }
}
```

### Caching Configuration

```nginx
http {
    proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=my_cache:10m;
    
    server {
        location / {
            proxy_cache my_cache;
            proxy_cache_valid 200 1h;
            proxy_cache_valid 404 1m;
            proxy_pass http://backend;
        }
    }
}
```

---

[<- Back: Continuous Deployment](./04-continuous-deployment.md) | [Next: Implementation Patterns ->](./06-implementation-patterns.md)
