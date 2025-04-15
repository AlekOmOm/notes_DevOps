# 03. Debugging Docker-compose 🐞

[<- Back to Hot Reload in Docker](./02-hot-reload-in-docker.md) | [Next: Agile Methodologies ->](./04-agile.md)

## Table of Contents

- [Common Debugging Techniques](#common-debugging-techniques)
- [Environment Variables](#environment-variables)
- [Networking Issues](#networking-issues)
- [Container Health Checks](#container-health-checks)
- [Practical Debugging Example](#practical-debugging-example)
- [Advanced Debugging Tools](#advanced-debugging-tools)

## Common Debugging Techniques

Debugging Docker-compose applications requires a methodical approach to identify issues across multiple containers and their interactions. Here are the essential commands and techniques:

### Basic Status and Information

```bash
# Check the status of all services
docker-compose ps

# Check the status of all services including stopped ones
docker-compose ps -a

# View logs for all services
docker-compose logs

# View logs for a specific service
docker-compose logs <service_name>

# Follow log output (like tail -f)
docker-compose logs -f <service_name>

# View service configuration
docker-compose config
```

### Container Inspection

```bash
# List all containers with port mappings
docker ps --format "{{.Names}}: {{.Ports}}"

# Get detailed information about a container
docker inspect <container_name>

# Get only network settings
docker inspect <container_name> --format='{{json .NetworkSettings.Networks}}' | jq
```

### Interacting with Containers

```bash
# Execute a command in a running container
docker-compose exec <service_name> <command>

# Get an interactive shell
docker-compose exec <service_name> bash  # or sh

# Check network connectivity from inside a container
docker-compose exec <service_name> ping <other_service>

# Check open ports in a container
docker-compose exec <service_name> ss -tuln

# Check environment variables
docker-compose exec <service_name> env
```

## Environment Variables

Environment variables are a common source of issues in Docker-compose applications:

### Defining Environment Variables

There are multiple ways to define environment variables in docker-compose:

```yaml
services:
  app:
    environment:
      # Method 1: Key-value pairs
      NODE_ENV: production
      DEBUG: "true"
      
      # Method 2: Array format
      - DATABASE_URL=postgres://user:pass@db:5432/dbname
      - REDIS_URL=redis://redis:6379
```

### Using .env Files

For better organization and security:

```yaml
services:
  app:
    env_file:
      - ./common.env
      - ./app.env
```

Where `app.env` might contain:
```
DATABASE_URL=postgres://user:pass@db:5432/dbname
NODE_ENV=development
```

### Checking Environment Variables

To verify environment variables in a running container:

```bash
docker-compose exec app env
docker-compose exec app env | grep DATABASE_URL
```

### Common Environment Variable Issues

- **Undefined variables**: No value is set, resulting in "undefined" in the application
- **Incorrect format**: Using wrong format in docker-compose.yml
- **Variable precedence**: Docker Compose environment variable precedence can be confusing
- **Scope issues**: Variables defined for one service are not automatically available to other services

## Networking Issues

Network connectivity is another common source of problems:

### Understanding Docker Networking

By default, Docker-compose creates a default network for your application:
- Services can reach each other using service names as hostnames
- Each service joins the network with the service name as its hostname

### Troubleshooting Network Connectivity

```bash
# Install diagnostic tools if needed
docker-compose exec app apt-get update
docker-compose exec app apt-get install -y iputils-ping

# Test connectivity between services
docker-compose exec app ping db

# Check if ports are open
docker-compose exec app ss -tuln

# Examine the Docker networks
docker network ls

# Inspect a specific network
docker network inspect <network_name>

# Check which networks a container is connected to
docker inspect <container_name> --format='{{json .NetworkSettings.Networks}}' | jq
```

### Common Network Issues

1. **Services on different networks**: Make sure all services that need to communicate are on the same network
2. **Port not exposed**: Ensure the internal port is exposed in the Dockerfile or docker-compose.yml
3. **Port binding conflicts**: Multiple services trying to bind to the same host port
4. **Hostname resolution**: Make sure you're using service names as defined in docker-compose.yml

## Container Health Checks

Health checks ensure your containers are not just running but actually working correctly:

```yaml
services:
  db:
    image: postgres
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 5s
      retries: 5
      start_period: 10s
  
  app:
    build: ./app
    depends_on:
      db:
        condition: service_healthy  # Only start after db is healthy
```

## Practical Debugging Example

Let's walk through a common scenario: An application that can't connect to its database.

### Step 1: Check container status

```bash
docker-compose ps
```

Ensure both the app and database containers are running.

### Step 2: Check logs for error messages

```bash
docker-compose logs app
```

Look for connection errors or specific error messages.

### Step 3: Verify environment variables

```bash
docker-compose exec app env | grep DB_
```

Check if database connection environment variables are set correctly.

### Step 4: Test network connectivity

```bash
docker-compose exec app ping db
```

If this fails, you may have a network configuration issue.

### Step 5: Check if the database port is accessible

```bash
docker-compose exec app apt-get update && apt-get install -y netcat
docker-compose exec app nc -zv db 5432
```

This tests if the database port is open and accepting connections.

### Step 6: Verify database service is working

```bash
docker-compose exec db pg_isready -U postgres
```

Check if the database service is actually ready to accept connections.

### Step 7: Inspect network configuration

```bash
docker network ls
docker inspect <app_container_id> --format='{{json .NetworkSettings.Networks}}' | jq
docker inspect <db_container_id> --format='{{json .NetworkSettings.Networks}}' | jq
```

Ensure both containers are on the same network.

## Advanced Debugging Tools

### Using Docker Debug

Docker Desktop now includes a dedicated debugging command:

```bash
docker debug <container_name>
```

This provides a persistent debugging environment with common tools pre-installed.

### Using Docker-compose Override Files

Create a `docker-compose.override.yml` for debugging:

```yaml
services:
  app:
    environment:
      DEBUG: "true"
    volumes:
      - ./debug-scripts:/debug-scripts
    command: ["sh", "-c", "tail -f /dev/null"]  # Keep container running without starting app
```

Then run:

```bash
docker-compose up -d
docker-compose exec app bash
```

This gives you a container with all the configuration but without starting the application, allowing for debugging.

### Remote Debugging

For language-specific debugging:

**Node.js:**
```yaml
services:
  app:
    command: ["node", "--inspect=0.0.0.0:9229", "app.js"]
    ports:
      - "9229:9229"  # Expose debug port
```

**Python:**
```yaml
services:
  app:
    command: ["python", "-m", "debugpy", "--listen", "0.0.0.0:5678", "app.py"]
    ports:
      - "5678:5678"  # Expose debug port
```

Then connect your IDE to the exposed debug port.

---

[<- Back to Hot Reload in Docker](./02-hot-reload-in-docker.md) | [Next: Agile Methodologies ->](./04-agile.md)
