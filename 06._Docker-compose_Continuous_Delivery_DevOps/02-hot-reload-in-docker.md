# 02. Hot Reload in Docker 🔄

[<- Back to Docker-compose](./01-docker-compose.md) | [Next: Debugging Docker-compose ->](./03-debug-docker-compose.md)

## Table of Contents

- [Understanding Hot Reload](#understanding-hot-reload)
- [Hot Reload Tools by Language](#hot-reload-tools-by-language)
- [Implementing Hot Reload in Docker](#implementing-hot-reload-in-docker)
- [Node.js Example with Nodemon](#nodejs-example-with-nodemon)
- [Volume Considerations](#volume-considerations)
- [Best Practices](#best-practices)

## Understanding Hot Reload

Hot reload (also called live reload) is a development feature that automatically refreshes or updates your application when you make changes to the source code. This eliminates the need to manually restart the application, significantly improving developer productivity.

### Benefits of Hot Reload

- **Faster development cycles**: Changes are immediately reflected
- **Preserved application state**: Many implementations maintain the current state
- **Better developer experience**: No context switching to restart services
- **Faster feedback loop**: Immediately see if changes work as expected

### Challenges with Docker

Docker containers isolate the application from the host environment, which creates challenges for hot reload:

1. **File system isolation**: Changes in the host file system aren't automatically visible inside containers
2. **Process management**: The containerized application needs to watch for changes
3. **Performance considerations**: Volume mounts can be slower, especially on macOS/Windows

## Hot Reload Tools by Language

Different programming languages have their own tools for enabling hot reload:

| Language | Tool | Description |
|----------|------|-------------|
| Python | Flask Debug Mode, Django Runserver | Built into many frameworks |
| Node.js | Nodemon, webpack-dev-server | Monitors file changes and restarts |
| Java | JRebel, Spring DevTools | Reloads classes without restart |
| Rust | cargo-watch | Watches source files and triggers commands |
| Ruby | Guard, Rerun | Monitors files and restarts processes |
| Go | Air, Realize | Provides live reload for Go applications |

**Note**: These tools are generally meant for development environments, not for production use.

## Implementing Hot Reload in Docker

The primary technique for hot reload in Docker involves:

1. **Bind mounts**: Mounting local source code into the container
2. **Watching tools**: Using tools that detect file changes and trigger rebuilds/restarts
3. **Docker-specific adjustments**: Ensuring file change notifications work correctly in containerized environments

### General Pattern

```yaml
services:
  app:
    build: 
      context: ./app
      dockerfile: Dockerfile.dev  # Often a separate dev Dockerfile
    volumes:
      - ./app:/app  # Mount source code
    command: npm run dev  # Run with dev mode / watching
```

## Node.js Example with Nodemon

### Step 1: Create a simple Express server

```javascript
// app.js
const express = require('express');
const app = express();

app.get('/', (req, res) => {
  res.send({ data: 'Hello, World!' });
});

app.listen(8080, () => {
  console.log('Server is running on port', 8080);
});
```

### Step 2: Create a development Dockerfile

```Dockerfile
# Dockerfile.dev
FROM node

WORKDIR /usr/src/app

COPY package*.json ./
RUN npm install

# Install nodemon globally
RUN npm install -g nodemon

COPY . .

# Use --legacy-watch for better performance in Docker
CMD npm config set prefer-offline true && nodemon --legacy-watch app.js
```

### Step 3: Create a docker-compose file

```yaml
# docker-compose.dev.yml
services:
  backend:
    build:
      context: ./node_project
      dockerfile: Dockerfile.dev
    ports:
      - "8080:8080"
    volumes:
      - ./node_project:/usr/src/app
      - backend_node_modules:/usr/src/app/node_modules

volumes:
  backend_node_modules:
```

### Step 4: Run with docker-compose

```bash
docker-compose -f docker-compose.dev.yml up --build
```

Now, any changes to files in the `node_project` directory will be detected by nodemon, which will automatically restart the Express server.

## Volume Considerations

When implementing hot reload, volume configuration is critical:

### Anonymous Volumes for Dependencies

To prevent node_modules in the container from being overwritten by an empty directory from the host:

```yaml
volumes:
  - ./src:/app/src  # Mount source code
  - /app/node_modules  # Anonymous volume to preserve node_modules
```

### Named Volumes for Better Performance

For improved performance and reliability:

```yaml
volumes:
  - ./src:/app/src  # Mount source code
  - app_node_modules:/app/node_modules  # Named volume

volumes:
  app_node_modules:  # Volume definition
```

### Volume Mount Options

Some applications may need specific mount options:

```yaml
volumes:
  - ./src:/app/src:delegated  # Performance option for macOS
```

## Best Practices

1. **Use separate Dockerfiles** for development and production
   ```
   Dockerfile.dev  # With hot reload tools installed
   Dockerfile      # Production-optimized build
   ```

2. **Cache dependencies** with named volumes
   ```yaml
   volumes:
     - app_node_modules:/app/node_modules
   ```

3. **Use the `--legacy-watch` flag** with nodemon in Docker to improve file change detection
   ```
   nodemon --legacy-watch app.js
   ```

4. **Consider polling** for environments where inotify events don't work well
   ```
   nodemon --legacy-watch --polling app.js
   ```

5. **Specify file extensions** to watch for faster performance
   ```
   nodemon --ext js,json,html app.js
   ```

6. **Mount only what's needed** to improve performance
   ```yaml
   volumes:
     - ./src:/app/src  # Only mount source code, not everything
   ```

7. **Use environment-specific compose files**
   ```
   docker-compose.yml        # Base configuration
   docker-compose.dev.yml    # Development overrides
   docker-compose.prod.yml   # Production overrides
   ```

---

[<- Back to Docker-compose](./01-docker-compose.md) | [Next: Debugging Docker-compose ->](./03-debug-docker-compose.md)
