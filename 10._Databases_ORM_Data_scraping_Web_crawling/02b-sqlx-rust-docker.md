# 2b. Docker with Rust and SQLx 🦀🐳

[<- Back to Database ORM](./01-database-orm.md) | [Current: 02 - Migrations](./02-migrations.md) |  [Next: Backup Documentation ->](./03-backup-documentation.md)

next: [02c - SQLx for CI/CD](./02c-sqlx-for-ci-cd.md)

---
- [02a - Migrations GitHub Actions](./02a-migrations-github-actions.md)
- [02b - SQLx in Rust with Docker environment](./02b-sqlx-rust-docker.md)
- [02c - SQLx for CI/CD](./02c-sqlx-for-ci-cd.md)
- [02d - SQLx Conceptual landscape](./02d-sqlx-conceptual-landscape.md)
---


## Table of Contents
- [Overview](#overview)
- [SQLx in Rust Applications](#sqlx-in-rust-applications)
- [Docker and SQLx Challenges](#docker-and-sqlx-challenges)
- [Database URL Management](#database-url-management)
- [CI/CD Pipeline Configuration](#cicd-pipeline-configuration)
- [Practical Solutions](#practical-solutions)
- [Advanced Configurations](#advanced-configurations)

## Overview

SQLx is a Rust SQL toolkit that provides compile-time checked queries without an ORM abstraction. When using SQLx in Docker environments, especially with CI/CD pipelines, several challenges arise related to database connectivity during build and runtime.

This guide addresses the specific challenges of:
1. Building Docker images with SQLx's compile-time checking
2. Handling database connections in CI/CD environments
3. Managing different database types (SQLite vs PostgreSQL)
4. Configuring database paths for deployment

## SQLx in Rust Applications

### Key Features of SQLx

SQLx shines with its unique approach to database access:

- **Compile-time SQL verification**: SQL queries are checked at compile time
- **Type-safe**: Full Rust type-safety for database operations
- **Multi-database support**: Works with SQLite, PostgreSQL, MySQL and MSSQL
- **Async-first**: Built for asynchronous Rust

```rust
// Example of compile-time verified query with SQLx
let users = sqlx::query!(
    "SELECT id, name FROM users WHERE active = ?",
    true
)
.fetch_all(&pool)
.await?;
```

### SQLite vs PostgreSQL in SQLx

Both databases are supported by SQLx but have different connection string formats:

**SQLite**:
```
sqlite:/path/to/database.db
sqlite::memory:  // In-memory database
```

**PostgreSQL**:
```
postgres://username:password@hostname:port/database
```

## Docker and SQLx Challenges

### The Compile-Time Checking Problem

SQLx's key feature—compile-time checking—creates a unique challenge when building Docker images:

1. SQLx needs an actual database connection during compilation
2. In CI/CD environments, the database file or server may not be accessible
3. The deployment database path often differs from the build environment path

This is especially problematic for SQLite where the database is a file that:
- Might not be in the git repository
- Has a different path in development vs. production

### Example Dockerfile with SQLx Issues

```dockerfile
FROM rust:1.68 as builder

WORKDIR /usr/src/app
COPY . .

# This will fail if DATABASE_URL points to a file that doesn't exist
RUN cargo build --release

FROM debian:buster-slim
COPY --from=builder /usr/src/app/target/release/my-app /usr/local/bin/

CMD ["my-app"]
```

## Database URL Management

### The SQLx Offline Mode Solution

SQLx provides an offline mode that enables builds without a database connection:

1. Generate a `sqlx-data.json` file in development:
   ```bash
   cargo sqlx prepare --database-url "sqlite:./dev.db"
   ```

2. Commit this file to your repository

3. Set the `SQLX_OFFLINE=true` environment variable during builds:
   ```dockerfile
   ENV SQLX_OFFLINE=true
   ```

### Implementing Offline Mode

```dockerfile
FROM rust:1.68 as builder

WORKDIR /usr/src/app
COPY . .

# Build with offline mode - no database needed
ENV SQLX_OFFLINE=true
RUN cargo build --release

FROM debian:buster-slim
COPY --from=builder /usr/src/app/target/release/my-app /usr/local/bin/

CMD ["my-app"]
```

## CI/CD Pipeline Configuration

### GitHub Actions Configuration

For a Rust Actix application using SQLx with SQLite:

```yaml
name: Build and Deploy

on:
  push:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install SQLx CLI
        run: cargo install sqlx-cli
      
      - name: Generate sqlx-data.json
        run: |
          # Create an empty database for preparing SQLx
          mkdir -p .sqlx
          touch .sqlx/temp.db
          DATABASE_URL=sqlite:.sqlx/temp.db cargo sqlx prepare --merged
      
      - name: Build Docker image
        env:
          SQLX_OFFLINE: true
        run: |
          docker build -t my-app .
      
      - name: Deploy
        env:
          DB_PATH: ${{ secrets.DB_PATH }}
        run: |
          # Deploy with the correct DB_PATH for production
          docker run -e DATABASE_URL="sqlite:$DB_PATH" my-app
```

### Runtime Database Configuration

For your specific case where:
- Development uses SQLite with SQLx
- DATABASE_URL should point to the deployment server's path
- The path is stored in GitHub Secrets

The solution requires separating build-time and runtime configurations:

```rust
// Example configuration.rs
use std::env;

pub fn get_database_url() -> String {
    // In production, use the DB_PATH from environment
    match env::var("DB_PATH") {
        Ok(path) => format!("sqlite:{}", path),
        // Fallback for development
        Err(_) => "sqlite:./development.db".to_string(),
    }
}
```

## Practical Solutions

### Solution 1: Two-Phase Configuration

Use a temporary database for build, then configure the real path at runtime:

```dockerfile
# Dockerfile
FROM rust:1.68 as builder

WORKDIR /usr/src/app
COPY . .

# Create temporary SQLite database for compilation
RUN mkdir -p .sqlx && touch .sqlx/temp.db
ENV DATABASE_URL=sqlite:.sqlx/temp.db

RUN cargo build --release

FROM debian:buster-slim
COPY --from=builder /usr/src/app/target/release/my-app /usr/local/bin/

# Will be overridden at runtime with the real path
ENV DATABASE_URL=sqlite:/path/to/db

CMD ["my-app"]
```

Then in your deployment script:

```bash
docker run -e DATABASE_URL="sqlite:$DB_PATH" my-app
```

### Solution 2: SQLite In-Memory for Build

Use an in-memory SQLite database for build:

```yaml
# GitHub Actions workflow
- name: Build with in-memory SQLite
  env:
    DATABASE_URL: "sqlite::memory:"
  run: |
    # Apply migrations to in-memory DB for schema
    cargo sqlx migrate run
    cargo build --release
```

### Solution 3: Separate Dev and Prod Configurations

Use `.env` files for development and environment variables for production:

```
# .env (development)
DATABASE_URL=sqlite:./dev.db

# .env.example (for documentation)
DATABASE_URL=sqlite:/path/to/your/database.db
```

Application code:

```rust
use dotenv::dotenv;
use std::env;

fn main() {
    // Load .env file if present (development)
    dotenv().ok();
    
    // Get DATABASE_URL from environment
    let database_url = env::var("DATABASE_URL")
        .expect("DATABASE_URL must be set");
        
    // Connect to database...
}
```

## Advanced Configurations

### Supporting Both SQLite and PostgreSQL

For applications that need to support both database types:

```rust
use sqlx::{Any, AnyPool, AnyPoolOptions};

async fn create_pool() -> Result<AnyPool, sqlx::Error> {
    let database_url = std::env::var("DATABASE_URL")
        .expect("DATABASE_URL must be set");
    
    let pool = AnyPoolOptions::new()
        .max_connections(5)
        .connect(&database_url)
        .await?;
    
    Ok(pool)
}
```

### Database Migration in Docker Entrypoint

Ensure migrations run when container starts:

```dockerfile
# Dockerfile
FROM rust:1.68 as builder
# ... build steps ...

FROM debian:buster-slim
COPY --from=builder /usr/src/app/target/release/my-app /usr/local/bin/
COPY --from=builder /usr/src/app/migrations /migrations
COPY --from=builder /usr/src/app/entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
```

```bash
#!/bin/bash
# entrypoint.sh

# Run migrations first
/usr/local/bin/my-app migrate

# Then start the application
exec /usr/local/bin/my-app
```

### Environment-Specific Database Configurations

For a setup that switches between SQLite and PostgreSQL based on environment:

```rust
use std::env;
use sqlx::{Pool, Any, AnyPool};

async fn create_pool() -> Result<AnyPool, sqlx::Error> {
    let env = env::var("APP_ENV").unwrap_or_else(|_| "development".to_string());
    
    let database_url = match env.as_str() {
        "production" => {
            // Use PostgreSQL in production
            env::var("POSTGRES_URL").expect("POSTGRES_URL must be set")
        }
        _ => {
            // Use SQLite in development
            env::var("SQLITE_PATH")
                .map(|path| format!("sqlite:{}", path))
                .unwrap_or_else(|_| "sqlite:./dev.db".to_string())
        }
    };
    
    // Connect using the Any pool which works with any database type
    let pool = sqlx::any::AnyPoolOptions::new()
        .max_connections(5)
        .connect(&database_url)
        .await?;
    
    Ok(pool)
}
```

---

[<- Back to Migrations](./02-migrations.md) | [Next: Backup Documentation ->](./03-backup-documentation.md)
