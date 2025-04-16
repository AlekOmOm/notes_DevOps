# 02. Hot Reload in Docker 🔄

[<- Back to Docker-compose](./01-docker-compose.md) | [Next: Debugging Docker-compose ->](./03-debug-docker-compose.md)

**Sub-notes**

1. [02a Hot Reload Docker - Rust-Actix](./02a-hot-reload-docker-implementation-in-rust-actix.md)

2. [02b Hot Reload Docker - Python-Flask](./02b-hot-reload-docker-implementation-in-python-flask.md)

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

| Language | Tool                               | Description                                |
| -------- | ---------------------------------- | ------------------------------------------ |
| Python   | Flask Debug Mode, Django Runserver | Built into many frameworks                 |
| Node.js  | Nodemon, webpack-dev-server        | Monitors file changes and restarts         |
| Java     | JRebel, Spring DevTools            | Reloads classes without restart            |
| Rust     | cargo-watch                        | Watches source files and triggers commands |
| Ruby     | Guard, Rerun                       | Monitors files and restarts processes      |
| Go       | Air, Realize                       | Provides live reload for Go applications   |

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
      dockerfile: Dockerfile.dev # Often a separate dev Dockerfile
    volumes:
      - ./app:/app # Mount source code
    command: npm run dev # Run with dev mode / watching
```

## Node.js Example with Nodemon

### Step 1: Create a simple Express server

```javascript
// app.js
const express = require("express");
const app = express();

app.get("/", (req, res) => {
  res.send({ data: "Hello, World!" });
});

app.listen(8080, () => {
  console.log("Server is running on port", 8080);
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

## Actix Web Example with cargo-watch

Rust requires a different approach for hot reloading due to its compiled nature. Let's implement hot reloading for an Actix Web application:

### Step 1: Understand the Actix Web application structure

```rust
// src/main.rs
use actix_files as fs;
use actix_web::{
    web, App, HttpResponse, HttpServer, middleware, get,
};
use log::info;
use std::env;

#[get("/api/health")]
async fn health_check() -> HttpResponse {
    HttpResponse::Ok().json(serde_json::json!({
        "status": "ok",
        "service": "frontend"
    }))
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    env_logger::init_from_env(env_logger::Env::new().default_filter_or("info"));

    // Get backend URL from environment or use default
    let backend_url = env::var("BACKEND_URL").unwrap_or_else(|_| "http://backend:8080".to_string());

    info!("Starting server at http://0.0.0.0:8080");
    info!("Using backend at {}", backend_url);

    HttpServer::new(move || {
        App::new()
            .wrap(middleware::Logger::default())
            .service(health_check)
            // Serve static files from the 'static' directory
            .service(fs::Files::new("/static", "./static").show_files_listing())
            // Serve HTML files from the root directory
            .service(fs::Files::new("/", "./static/html")
                .index_file("search.html")
                .default_handler(web::to(|| async {
                    HttpResponse::NotFound().body("Not Found")
                })))
    })
    .bind("0.0.0.0:8080")?
    .run()
    .await
}
```

### Step 2: Create a development Dockerfile

```Dockerfile
# Dockerfile.dev
FROM rust:1.81-slim

WORKDIR /usr/src/app

# Install cargo-watch for hot reloading
RUN cargo install cargo-watch cargo-make

# Install system dependencies
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy Cargo files for dependency caching
COPY Cargo.toml Cargo.lock ./

# Create dummy src to build dependencies
RUN mkdir -p src && echo "fn main() {}" > src/main.rs
RUN cargo build

# The actual source code will be mounted at runtime
CMD ["cargo", "watch", "-x", "run", "--poll"]
```

### Step 3: Create a Makefile.toml for development tasks

```toml
# Makefile.toml
[tasks.dev]
description = "Development mode with hot reload"
install_crate = { crate_name = "cargo-watch", binary = "cargo-watch", test_arg = "--help" }
command = "cargo"
args = ["watch", "-x", "run", "--poll"]

[tasks.dev-check]
description = "Development mode with compile checking"
install_crate = { crate_name = "cargo-watch", binary = "cargo-watch", test_arg = "--help" }
command = "cargo"
args = ["watch", "-x", "check -x clippy -x run"]

[tasks.dev-docker]
description = "Run development environment in Docker"
command = "docker-compose"
args = ["-f", "docker-compose.dev.yml", "up", "--build"]
```

### Step 4: Create a docker-compose file for development

```yaml
# docker-compose.dev.yml
version: "3.8"

services:
  frontend:
    build:
      context: .
      dockerfile: Dockerfile.dev
    ports:
      - "8080:8080"
    volumes:
      - ./src:/usr/src/app/src
      - ./Cargo.toml:/usr/src/app/Cargo.toml
      - ./Cargo.lock:/usr/src/app/Cargo.lock
      - ./static:/usr/src/app/static
      - ./Makefile.toml:/usr/src/app/Makefile.toml
      - cargo_cache:/usr/local/cargo/registry
      - target_cache:/usr/src/app/target
    environment:
      - RUST_BACKTRACE=1
      - RUST_LOG=debug
      - BACKEND_URL=http://backend:8080

volumes:
  cargo_cache:
  target_cache:
```

### Step 5: Run with docker-compose or cargo-make

```bash
# Using Docker Compose directly
docker-compose -f docker-compose.dev.yml up --build

# Or using cargo-make (if installed)
cargo make dev-docker
```

### Step 6: Develop with hot reload

With this setup, any changes to Rust files in the `src` directory will trigger:

1. Cargo detecting the changes (via cargo-watch)
2. Recompilation of the affected files
3. Restarting the Actix Web server

Changes to static files will also be immediately available since they're mounted into the container.

## Volume Considerations

When implementing hot reload, volume configuration is critical:

### Anonymous Volumes for Dependencies

To prevent node_modules in the container from being overwritten by an empty directory from the host:

```yaml
volumes:
  - ./src:/app/src # Mount source code
  - /app/node_modules # Anonymous volume to preserve node_modules
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
  - ./src:/app/src:delegated # Performance option for macOS
```

## Rust/Actix Web Hot Reload Implementation

Implementing hot reload for Rust applications requires a different approach than interpreted languages like JavaScript or Python. Let's create a development setup for Actix Web with hot reload:

### Setting Up Cargo Watch

[cargo-watch](https://github.com/watchexec/cargo-watch) is a tool that watches your source files and runs a command when they change, making it ideal for hot reloading Rust applications.

#### Installing cargo-watch

First, you need to install cargo-watch:

```bash
cargo install cargo-watch
```

#### Using cargo-watch with Actix Web

For an Actix Web application:

```bash
cargo watch -x 'run --bin frontend'
```

This will watch your source files and recompile and restart your application whenever they change.

### Using cargo-make for Development Workflow

[cargo-make](https://github.com/sagiegurari/cargo-make) is a task runner and build tool that can be used to define and organize development tasks.

#### Installing cargo-make

```bash
cargo install cargo-make
```

#### Creating a Makefile.toml

Create a `Makefile.toml` in your project root:

```toml
[tasks.dev]
description = "Development mode with hot reload"
install_crate = "cargo-watch"
command = "cargo"
args = ["watch", "-x", "run"]

[tasks.dev-check]
description = "Development mode with compile checking"
install_crate = "cargo-watch"
command = "cargo"
args = ["watch", "-x", "check -x run"]
```

Now you can start your development environment with:

```bash
cargo make dev
```

### Docker Development Setup for Actix Web

Here's how to implement hot reload for an Actix Web application in Docker:

#### Dockerfile.dev for Actix Web

```Dockerfile
# Dockerfile.dev
FROM rust:1.81-slim

WORKDIR /usr/src/app

# Install cargo-watch for hot reloading
RUN cargo install cargo-watch

# Install system dependencies
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy just the Cargo.toml and Cargo.lock files first
COPY Cargo.toml Cargo.lock ./

# Create a dummy main.rs to build dependencies
RUN mkdir -p src && echo "fn main() {println!(\"Dummy\");}" > src/main.rs
RUN cargo build

# Remove the dummy source
RUN rm -rf src

# The source code will be mounted at runtime
CMD ["cargo", "watch", "-x", "run", "--poll"]
```

#### Docker Compose for Development

```yaml
# docker-compose.dev.yml
version: "3.8"

services:
  frontend:
    build:
      context: .
      dockerfile: Dockerfile.dev
    ports:
      - "8080:8080"
    volumes:
      - ./src:/usr/src/app/src
      - ./Cargo.toml:/usr/src/app/Cargo.toml
      - ./Cargo.lock:/usr/src/app/Cargo.lock
      - ./static:/usr/src/app/static
      - cargo_cache:/usr/local/cargo/registry
      - target_cache:/usr/src/app/target
    environment:
      - RUST_BACKTRACE=1
      - RUST_LOG=debug

volumes:
  cargo_cache:
  target_cache:
```

### Concrete Example for the Provided Actix Web App

Given your specific Actix Web application:

#### 1. Enhanced Dockerfile.dev

```Dockerfile
# Dockerfile.dev
FROM rust:1.81-slim

WORKDIR /usr/src/app

# Install cargo-watch and cargo-make
RUN cargo install cargo-watch cargo-make

# Install system dependencies
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy Cargo files
COPY Cargo.toml Cargo.lock ./

# Create dummy src to build dependencies
RUN mkdir -p src && echo "fn main() {}" > src/main.rs
RUN cargo build

# Set environment variables
ENV RUST_BACKTRACE=1
ENV RUST_LOG=debug

# Command for development with hot reload
CMD ["cargo", "watch", "-x", "run", "--poll"]
```

#### 2. Advanced Makefile.toml

```toml
[tasks.dev]
description = "Development mode with hot reload"
install_crate = { crate_name = "cargo-watch", binary = "cargo-watch", test_arg = "--help" }
command = "cargo"
args = ["watch", "-x", "run", "--poll"]

[tasks.dev-check]
description = "Development mode with compile checking"
install_crate = { crate_name = "cargo-watch", binary = "cargo-watch", test_arg = "--help" }
command = "cargo"
args = ["watch", "-x", "check -x clippy -x run"]

[tasks.lint]
description = "Run clippy"
command = "cargo"
args = ["clippy"]

[tasks.fmt]
description = "Format code"
command = "cargo"
args = ["fmt"]

[tasks.dev-docker]
description = "Run development environment in Docker"
command = "docker-compose"
args = ["-f", "docker-compose.dev.yml", "up", "--build"]
```

#### 3. Enhanced Docker Compose

```yaml
# docker-compose.dev.yml
version: "3.8"

services:
  frontend:
    build:
      context: .
      dockerfile: Dockerfile.dev
    ports:
      - "8080:8080"
    volumes:
      - ./src:/usr/src/app/src
      - ./Cargo.toml:/usr/src/app/Cargo.toml
      - ./Cargo.lock:/usr/src/app/Cargo.lock
      - ./static:/usr/src/app/static
      - ./Makefile.toml:/usr/src/app/Makefile.toml
      - cargo_cache:/usr/local/cargo/registry
      - target_cache:/usr/src/app/target
    environment:
      - RUST_BACKTRACE=1
      - RUST_LOG=debug
      - BACKEND_URL=http://backend:8080

volumes:
  cargo_cache:
  target_cache:
```

### Running the Development Environment

```bash
# With Docker Compose directly
docker-compose -f docker-compose.dev.yml up --build

# Or using cargo-make
cargo make dev-docker
```

### Performance Considerations for Rust

1. **Incremental compilation**: This significantly speeds up rebuilds but might still be slower than interpreted languages.

2. **Split target mounting**: Use separate volumes for `target` and `cargo` directories to maintain build artifacts between runs.

3. **Cache dependencies**: Pre-build dependencies to reduce rebuild times.

4. **Mount only source files**: Don't mount the entire project directory to avoid unnecessary rebuilds.

5. **Use --poll option**: Particularly helpful in Docker environments where filesystem events may not work reliably.

## Best Practices for Hot Reload

1. **Use separate Dockerfiles** for development and production

   ```
   Dockerfile.dev   # With hot reload tools installed
   Dockerfile       # Production-optimized build
   ```

2. **Cache build artifacts** with named volumes

   ```yaml
   volumes:
     - cargo_cache:/usr/local/cargo/registry
     - target_cache:/usr/src/app/target
   ```

3. **Use polling** for environments where filesystem events don't work well

   ```
   cargo watch -x run --poll
   ```

4. **Consider target-specific options** to optimize compilation

   ```toml
   # In .cargo/config.toml
   [target.x86_64-unknown-linux-gnu]
   rustflags = ["-C", "target-cpu=native"]
   ```

5. **Mount only what's needed** to improve performance

   ```yaml
   volumes:
     - ./src:/app/src # Only mount source code, not everything
   ```

6. **Use environment-specific compose files**
   ```
   docker-compose.yml        # Base configuration
   docker-compose.dev.yml    # Development overrides
   docker-compose.prod.yml   # Production overrides
   ```

---

[<- Back to Docker-compose](./01-docker-compose.md) | [Next: Debugging Docker-compose ->](./03-debug-docker-compose.md)
