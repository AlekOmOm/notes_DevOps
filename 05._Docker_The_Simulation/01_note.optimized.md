# DevOps Build Tools & Containerization Guide

## 1. Build Tools & Package Management

### OS-Level Package Managers
- **Windows**: chocolatey
- **macOS**: homebrew
- **Linux**: apt, yum, dnf, pacman, zypper, portage, rpm, snap, flatpak, nix

### Language-Specific Package Managers
- **Python**: pip, poetry, conda
- **JavaScript**: npm, yarn, pnpm
- **Java**: maven, gradle
- **Ruby**: gem, bundler
- **Rust**: cargo
- **Go**: go mod
- **PHP**: composer

### Build Tool Recommendations
- **Python**: poetry for dependency management and virtual environments
- Use appropriate build tools based on language ecosystem needs

## 2. Packaging Concepts

### Distribution Methods
- **Source Code**: .zip/.tar.gz, GitHub Releases
- **Binary**: .exe, .dmg, .deb, .rpm
- **Containers**: Docker, Kubernetes
- **Libraries**: npm modules, Python packages

### Semantic Versioning
- **MAJOR**: Incompatible API changes
- **MINOR**: Backward compatible new functionality
- **PATCH**: Backward compatible bug fixes
- Format: `MAJOR.MINOR.PATCH`

## 3. Virtualization vs. Containerization

### Virtualization
- Creates complete virtual machines with dedicated OS
- Uses hypervisors to manage guest VMs
- Higher resource overhead but complete isolation

### Containerization
- Lightweight execution environments sharing host kernel
- Isolated user space only
- Much lower overhead than VMs

### Container Benefits
- **Faster Setup**: Single command deployment
- **Portability**: Run anywhere with container runtime
- **Reproducibility**: Consistent environments across systems
- **Isolation**: Separate dependencies per application
- **Scalability**: Easier service scaling

### Key Container Technologies
- **Linux Kernel Features**: Namespaces and cgroups
- **Modern Runtimes**: containerd, Podman, Docker

## 4. Docker Fundamentals

### Core Concepts
- **Image**: Blueprint/recipe for containers
- **Container**: Running instance of an image
- **Volume**: Persistent data storage
- **Network**: Container communication system

### Basic Docker Commands
```bash
# Run a container
docker run --rm hello-world

# Run in detached mode
docker run -d redis

# List running containers
docker ps

# Stop a container
docker stop <container-id>

# Interactive shell
docker run -it --rm alpine /bin/sh
```

### Docker Volumes
```bash
# Create a volume
docker volume create test-volume

# Mount a volume
docker run -it -v test-volume:/data alpine

# Mount local directory
docker run -it -v ./mydata:/container-data alpine
```

### Docker Networking
```bash
# Create a network
docker network create mynetwork

# Run containers on a network
docker run -dit --name container1 --network mynetwork alpine
docker run -dit --name container2 --network mynetwork alpine

# Expose ports
docker run -dit -p 8080:80 nginx
```

## 5. Dockerfile Guide

### Basic Structure
```dockerfile
FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["python", "app.py"]
```

### Key Instructions
- **FROM**: Base image
- **WORKDIR**: Working directory in container
- **COPY**: Copy files from host to container
- **RUN**: Execute commands during build
- **EXPOSE**: Document container port
- **CMD**: Default command to run
- **ENTRYPOINT**: Container entry command

### RUN vs CMD vs ENTRYPOINT
- **RUN**: Build-time commands, creates layers
- **CMD**: Default command, can be overridden at runtime
- **ENTRYPOINT**: Main executable, parameters can be passed

### Optimization Techniques
1. **Layer Caching**: Order instructions to maximize cache hits
2. **Multi-stage Builds**: Use build stages to minimize final image size
3. **.dockerignore**: Exclude unnecessary files
4. **Non-root Users**: Create dedicated users for security

### Best Practices
- Keep container single-purpose
- Minimize layers
- Use specific image tags
- Use .dockerignore
- Create non-root user
- Keep images small

## 6. Security Considerations

### Container Security
- Use official/verified base images
- Apply security updates regularly
- Avoid running as root
- Scan images for vulnerabilities
- Implement least privilege principle

### Configuration Management
- Use environment variables for configuration
- Avoid hardcoding secrets
- Use volume mounts for sensitive data
- Implement proper secret management

## 7. DevOps Integration

### CI/CD Integration
- Automate builds with GitHub Actions
- Implement container registry integration
- Set up automated testing of containers
- Configure deployment strategies

### Monitoring & Logging
- Implement health checks
- Configure container logging
- Set up container monitoring
- Establish alerting mechanisms

## 8. Practical Examples

### Python Flask Containerization
```dockerfile
FROM python:3.9-slim

# Add non-root user
RUN adduser --system --home /home/appuser appuser

WORKDIR /app

# Copy and install dependencies first (for layer caching)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Switch to non-root user
USER appuser

# Document the port
EXPOSE 8080

# Run the application
CMD ["python", "app.py"]
```

### Node.js Containerization
```dockerfile
FROM node:16-alpine

# Create app directory
WORKDIR /usr/src/app

# Install dependencies first (for layer caching)
COPY package*.json ./
RUN npm ci --only=production

# Copy app source
COPY . .

# Switch to non-root user
USER node

# Document the port
EXPOSE 8080

# Run the app
CMD ["node", "app.js"]
```
