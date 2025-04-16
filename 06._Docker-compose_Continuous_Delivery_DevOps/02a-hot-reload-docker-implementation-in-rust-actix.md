# 02a. Hot Reload Docker Implementation in Rust Actix 🦀

[<- Back: Hot Reload in Docker](./02-hot-reload-in-docker.md) | [Hot Reload Docker - Python-Flask implementation](./02b-hot-reload-docker-implementation-in-python-flask.md) | [Next: Debugging Docker-compose ->](./03-debug-docker-compose.md)

## Table of Contents

- [Understanding Rust Development in Docker](#understanding-rust-development-in-docker)
- [Setting Up cargo-watch](#setting-up-cargo-watch)
- [Using cargo-make for Development Workflow](#using-cargo-make-for-development-workflow)
- [Docker Development Setup for Actix Web](#docker-development-setup-for-actix-web)
- [Example Actix Web Application](#example-actix-web-application)
- [Performance Optimizations](#performance-optimizations)
- [Production vs Development Setup](#production-vs-development-setup)

## Understanding Rust Development in Docker

Rust's compiled nature creates unique challenges for hot reloading in Docker:

1. **Compilation time**: Rust requires full recompilation when files change
2. **Build artifacts**: Efficient caching of dependencies and build artifacts is crucial
3. **File system watching**: The container needs to reliably detect file changes
4. **Resource usage**: Compilation is CPU and memory intensive

Despite these challenges, a well-configured Docker environment can provide an excellent Rust development experience.

## Setting Up cargo-watch

[cargo-watch](https://github.com/watchexec/cargo-watch) is a tool that watches your source files and runs a command when they change, making it ideal for hot reloading Rust applications.

### Installing cargo-watch

```bash
cargo install cargo-watch
```

### Basic cargo-watch Usage

```bash
# Run application when files change
cargo watch -x run

# Run tests when files change
cargo watch -x test

# Chain multiple commands
cargo watch -x 'check -x test -x run'

# Use polling (important in Docker)
cargo watch -x run --poll
```

## Using cargo-make for Development Workflow

[cargo-make](https://github.com/sagiegurari/cargo-make) is a Rust task runner and build tool that enhances the development workflow.

### Installing cargo-make

```bash
cargo install cargo-make
```

### Makefile.toml Example for Actix Web

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

With this file, you can run:

```bash
# Start development mode
cargo make dev

# Start with linting
cargo make dev-check

# Start Docker development environment
cargo make dev-docker
```

## Docker Development Setup for Actix Web

Creating an efficient Docker development environment for Actix Web requires careful configuration.

### Dockerfile.dev

```Dockerfile
FROM rust:1.81-slim

WORKDIR /usr/src/app

# Install development tools
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

# Set environment variables
ENV RUST_BACKTRACE=1
ENV RUST_LOG=debug

# Command for development with hot reload
CMD ["cargo", "watch", "-x", "run", "--poll"]
```

### Optimized docker-compose.dev.yml

```yaml
version: "3.8"

services:
  frontend:
    build:
      context: .
      dockerfile: Dockerfile.dev
    ports:
      - "8080:8080"
    volumes:
      # Mount source code files
      - ./src:/usr/src/app/src
      - ./Cargo.toml:/usr/src/app/Cargo.toml
      - ./Cargo.lock:/usr/src/app/Cargo.lock

      # Mount static assets
      - ./static:/usr/src/app/static

      # Mount Makefile for cargo-make
      - ./Makefile.toml:/usr/src/app/Makefile.toml

      # Cache dependencies and build artifacts
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

### Key Docker Configuration Elements

1. **Build caching strategy**:

   - Pre-build dependencies with dummy main.rs
   - Mount only source files, not target directory

2. **Volume configuration**:

   - Source code volumes for hot reload
   - Named volumes for cargo cache and target directory
   - Static assets mounted for immediate updates

3. **Development environment**:
   - RUST_BACKTRACE for better error reporting
   - RUST_LOG for detailed logging
   - Application-specific environment variables

## Example Actix Web Application

Let's implement hot reload for a typical Actix Web application:

### Application Structure

```
project/
  ├── src/
  │    └── main.rs
  ├── static/
  │    ├── css/
  │    ├── js/
  │    └── html/
  ├── Cargo.toml
  ├── Cargo.lock
  ├── Dockerfile
  ├── Dockerfile.dev
  ├── Makefile.toml
  └── docker-compose.dev.yml
```

### Example Application Code (main.rs)

```rust
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

### Project Dependencies (Cargo.toml)

```toml
[package]
name = "frontend"
version = "0.1.0"
edition = "2021"

[dependencies]
actix-web = "4.4.0"
actix-files = "0.6.2"
actix-rt = "2.9.0"
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
env_logger = "0.10.0"
log = "0.4"
dotenv = "0.15.0"

[profile.dev]
opt-level = 0
debug = true
debug-assertions = true
overflow-checks = true
lto = false
panic = 'unwind'
incremental = true
codegen-units = 256
```

## Running the Development Environment

Here's how to use this setup:

```bash
# Start development environment
docker-compose -f docker-compose.dev.yml up --build

# Or, using cargo-make
cargo make dev-docker
```

Once running, you can:

1. Edit files in the `src` directory to update application logic
2. Modify static files in the `static` directory for immediate asset updates
3. See real-time logs in the terminal

## Performance Optimizations

Rust compilation in Docker can be slow. Here are strategies to improve performance:

### 1. Rust-specific Compiler Options

Add a `.cargo/config.toml` file:

```toml
[build]
# Use incremental compilation
incremental = true

# Optimize for faster development builds
[profile.dev]
opt-level = 0
debug = true
debug-assertions = true
overflow-checks = true
lto = false
codegen-units = 256

# Optimize for better CPU usage on host machine
[target.x86_64-unknown-linux-gnu]
rustflags = ["-C", "target-cpu=native"]
```

### 2. Volume Mount Optimization

```yaml
volumes:
  # Only mount what changes frequently
  - ./src:/usr/src/app/src

  # Use named volumes for large directories with many files
  - cargo_cache:/usr/local/cargo/registry
  - target_cache:/usr/src/app/target
```

### 3. Docker Configuration

For macOS and Windows, consider these Docker Desktop settings:

- Increase RAM allocation (at least 4GB)
- Increase CPU allocation
- Use the VirtioFS file sharing implementation if available

### 4. Selective Watching

Configure cargo-watch to only watch relevant files:

```bash
cargo watch -x run --poll -i "**/*.md" -i "**/*.git*"
```

## Production vs Development Setup

The development setup differs significantly from production:

### Development Dockerfile (Dockerfile.dev)

```Dockerfile
FROM rust:1.81-slim

WORKDIR /usr/src/app

# Install development tools
RUN cargo install cargo-watch cargo-make

# ... dependency installation ...

# Development mode with hot reload
CMD ["cargo", "watch", "-x", "run", "--poll"]
```

### Production Dockerfile (Dockerfile)

```Dockerfile
# Build stage
FROM rust:1.81-slim AS builder

WORKDIR /usr/src/app
COPY Cargo.toml Cargo.lock ./

# Create empty src/main.rs to build dependencies
RUN mkdir -p src && echo "fn main() {}" > src/main.rs
RUN cargo build --release

# Build the actual application
COPY src ./src
RUN touch src/main.rs && cargo build --release

# Runtime stage
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy binary from build stage
COPY --from=builder /usr/src/app/target/release/frontend .

# Copy static files
COPY static ./static

# Expose the port
EXPOSE 8080

# Run the binary
CMD ["./frontend"]
```

This multi-stage production build creates a much smaller image without development tools, improving security and reducing size.

---

[<- Back: Hot Reload in Docker](./02-hot-reload-in-docker.md) | [Hot Reload Docker - Python-Flask implementation](./02b-hot-reload-docker-implementation-in-python-flask.md) | [Next: Debugging Docker-compose ->](./03-debug-docker-compose.md)
