# 01. Docker-compose 🐳

[<- Back to Main Note](./README.md) | [Next: Hot Reload in Docker ->](./02-hot-reload-in-docker.md)

## Table of Contents

- [Introduction to Docker-compose](#introduction-to-docker-compose)
- [Docker-compose vs Docker compose](#docker-compose-vs-docker-compose)
- [Defining Services, Networks, and Volumes](#defining-services-networks-and-volumes)
- [Networking in Docker-compose](#networking-in-docker-compose)
- [Volumes vs Bind Mounts](#volumes-vs-bind-mounts)
- [Practical Examples](#practical-examples)
- [Using Makefiles with Docker-compose](#using-makefiles-with-docker-compose)

## Introduction to Docker-compose

Docker-compose is a tool for defining and running multi-container Docker applications. With Compose, you use a YAML file to configure your application's services, networks, and volumes. Then, with a single command, you create and start all the services defined in your configuration.

Docker-compose simplifies the process of:
- Defining the services that make up your application
- Running multiple containers simultaneously
- Setting up networks between containers
- Managing data persistence through volumes
- Starting, stopping, and rebuilding services

Docker-compose is particularly valuable for:
- Development environments
- Testing and staging setups
- CI/CD workflows
- Simple deployment scenarios

## Docker-compose vs Docker compose

There are two ways to use Docker Compose:

1. **docker-compose**: The original standalone Python-based tool
   - Installed separately (`brew install docker-compose`, `choco install docker-compose`, etc.)
   - The legacy approach but still widely used

2. **docker compose**: The newer Go implementation built into Docker CLI
   - Included with Docker Desktop and recent Docker installations
   - Gradually replacing the standalone tool

Important differences:

```bash
# Using the standalone tool
$ docker-compose build web
# Creates image: node_project_web (uses underscores)

# Using the Docker CLI plugin
$ docker compose build web
# Creates image: node_project-web (uses hyphens)
```

This distinction matters when referencing image names in scripts or other containers. For consistency, the course material uses `docker-compose`.

## Defining Services, Networks, and Volumes

A typical `docker-compose.yml` file includes:

```yaml
version: '3.8'  # Compose file format version
services:       # Container definitions
  backend:
    build: ./backend
    ports:
      - "8080:8080"
    environment:
      DB_HOST: db
    networks:
      - app_network
    depends_on:
      - db
  
  db:
    image: postgres:14
    volumes:
      - db_data:/var/lib/postgresql/data
    environment:
      POSTGRES_PASSWORD: example
    networks:
      - app_network

volumes:        # Persistent data storage
  db_data:
    driver: local

networks:       # Communication channels
  app_network:
    driver: bridge
```

### Key Components:

- **services**: Containers that make up your application
- **volumes**: Persistent data storage that exists beyond container lifecycles
- **networks**: Communication channels between containers
- **depends_on**: Service start order and dependencies
- **environment**: Environment variables passed to containers

## Networking in Docker-compose

When you run `docker-compose up`, several networking operations occur:

1. A default network is created (named after your project directory plus "_default")
2. Each service joins this network using its service name as the hostname
3. Services can communicate with each other using service names as DNS names

For example, in the setup above:
- The backend service can connect to the database using `db` as the hostname
- This hostname resolution works automatically within the Docker network

You can also create custom networks with specific drivers:

```yaml
networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true  # No external access
```

Services can then be assigned to specific networks:

```yaml
services:
  web:
    networks:
      - frontend
  api:
    networks:
      - frontend
      - backend
  db:
    networks:
      - backend
```

This creates a layered network architecture where `api` can talk to both `web` and `db`, but `web` and `db` cannot communicate directly.

## Volumes vs Bind Mounts

Docker-compose supports two primary ways to persist data:

### Volumes

Volumes are fully managed by Docker:
- Created and managed by Docker
- Stored in a part of the host filesystem managed by Docker
- Not affected by filesystem changes on the host
- Can be managed with Docker CLI commands
- Can be shared and reused among containers
- Better performance on Windows and macOS

```yaml
volumes:
  postgres_data:  # Named volume declaration
    
services:
  db:
    volumes:
      - postgres_data:/var/lib/postgresql/data  # Using the named volume
```

### Bind Mounts

Bind mounts depend on the host filesystem:
- Use a specific path on the host
- Can be accessed and modified by processes outside Docker
- Depend on the host machine's directory structure
- Useful for development when you need to make changes on the host

```yaml
services:
  web:
    volumes:
      - ./src:/app/src  # Bind mount (host path : container path)
```

**When to use which?**
- Use **volumes** for persistent data (databases, etc.)
- Use **bind mounts** for development (code, configuration files)

## Practical Examples

### Example 1: Web Application with Database

```yaml
version: '3.8'
services:
  app:
    build:
      context: ./app
      dockerfile: Dockerfile
    ports:
      - "3000:80"
    environment:
      - NODE_ENV=development
      - DB_HOST=db
      - DB_USER=postgres
      - DB_PASSWORD=example
      - DB_NAME=myapp
    volumes:
      - ./app:/usr/src/app
      - /usr/src/app/node_modules
    depends_on:
      - db

  db:
    image: postgres:14
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=example
      - POSTGRES_DB=myapp
    volumes:
      - pgdata:/var/lib/postgresql/data
    ports:
      - "5432:5432"

volumes:
  pgdata:
```

### Example 2: Nginx with Configuration

```yaml
version: '3.8'
services:
  nginx:
    image: nginx:latest
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./html:/usr/share/nginx/html
```

The corresponding `nginx.conf` file:

```
events { worker_connections 1024; }

http {
    server {
        listen 80;
        
        location / {
            root /usr/share/nginx/html;
            index index.html index.htm;
        }
    }
}
```

## Using Makefiles with Docker-compose

Makefiles can simplify Docker-compose commands, making them more memorable and easier to execute:

```makefile
.PHONY: up down build logs clean

up:
	@echo "Starting services..."
	docker-compose up -d

down:
	@echo "Stopping services..."
	docker-compose down

build:
	@echo "Building services..."
	docker-compose build

logs:
	@echo "Showing logs..."
	docker-compose logs -f

clean:
	@echo "Cleaning up..."
	docker-compose down -v --rmi all --remove-orphans
```

With this Makefile, you can:
- Start services with `make up`
- Stop services with `make down`
- Build services with `make build`
- View logs with `make logs`
- Clean everything with `make clean`

This approach is:
- More readable than long Docker commands
- Easy to document and standardize
- Self-documenting for new team members
- Compatible with CI/CD systems

---

[<- Back to Main Note](./README.md) | [Next: Hot Reload in Docker ->](./02-hot-reload-in-docker.md)
