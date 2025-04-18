# 2c. SQLx CI/CD Workflow 🔄

[<- Back to Database ORM](./01-database-orm.md) | [Current: 02 - Migrations](./02-migrations.md) | [Next: Backup Documentation ->](./03-backup-documentation.md)

next: [02d - SQLx Conceptual Landscape](./02d-sqlx-conceptual-landscape.md)

---
- [02a - Migrations GitHub Actions](./02a-migrations-github-actions.md)
- [02b - SQLx in Rust with Docker environment](./02b-sqlx-rust-docker.md)
- [02c - SQLx for CI/CD](./02c-sqlx-for-ci-cd.md)
- [02d - SQLx Conceptual Landscape](./02d-sqlx-conceptual-landscape.md)
---

## Table of Contents
- [Introduction](#introduction)
- [SQLx Compile-Time Checking Challenge](#sqlx-compile-time-checking-challenge)
- [Preparing SQLx for CI/CD](#preparing-sqlx-for-cicd)
- [GitHub Actions Workflow](#github-actions-workflow)
- [Deployment Strategies](#deployment-strategies)
- [Troubleshooting](#troubleshooting)
- [Conclusion](#conclusion)

## Introduction

This guide addresses the specific challenges of integrating SQLx-based Rust applications into continuous integration and deployment workflows. It focuses on maintaining SQLx's compile-time checking benefits while addressing the constraints of CI/CD environments.

## SQLx Compile-Time Checking Challenge

The core challenge with SQLx in CI/CD pipelines stems from its unique compile-time checking mechanism:

1. **Standard build process**: SQLx connects to a database during compilation to verify SQL queries
2. **CI environment limitation**: Build servers typically don't have access to your database
3. **Deployment constraint**: Database paths/credentials differ between build and runtime environments

This presents a fundamental challenge: *How do you build the application when the target database doesn't exist in the build environment?*

## Preparing SQLx for CI/CD

### The SQLx Offline Mode

SQLx provides an elegant solution through "offline mode" which caches query metadata:

```bash
# Generate metadata file during development
cargo sqlx prepare --database-url "sqlite:./dev.db" --merged
```

This command creates a `sqlx-data.json` file containing:
- SQL query text
- Parameter types
- Result types
- Database-specific metadata

This file should be committed to your repository, enabling builds without a database connection. This file contains the metadata SQLx needs for offline compilation and should be committed to your repository to version your database schema expectations alongside your code.

### Setting Up Your Project

1. **Enable offline mode in Cargo.toml**:
   ```toml
   [dependencies]
   sqlx = { version = "0.7", features = [
     "runtime-tokio-rustls",
     "sqlite",         # Or "postgres"
     "migrate",
     "json",
     "offline"         # Important for CI/CD
   ]}
   ```

2. **Create a prepare script**:
   ```bash
   #!/bin/bash
   # prepare-sqlx.sh
   
   # Create development database in a dedicated directory
   mkdir -p .sqlx
   touch .sqlx/dev.db
   
   # Run migrations to ensure schema is up-to-date
   cargo sqlx migrate run --database-url sqlite:.sqlx/dev.db
   
   # Generate SQLx metadata file
   cargo sqlx prepare --database-url sqlite:.sqlx/dev.db --merged
   
   echo "SQLx metadata prepared for offline mode"
   ```

3. **Add sqlx-data.json to version control**:
   ```bash
   git add sqlx-data.json
   git commit -m "Add SQLx metadata for offline builds"
   ```

## GitHub Actions Workflow

Here's a comprehensive GitHub Actions workflow for a Rust Actix application with SQLx:

```yaml
name: Build and Deploy

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install Rust toolchain
        uses: actions-rs/toolchain@v1
        with:
          profile: minimal
          toolchain: stable
          override: true
      
      - name: Cache dependencies
        uses: actions/cache@v3
        with:
          path: |
            ~/.cargo/registry
            ~/.cargo/git
            target
          key: ${{ runner.os }}-cargo-${{ hashFiles('**/Cargo.lock') }}
      
      # Enable SQLx offline mode for CI builds (used during compile-time checks)
      - name: Configure SQLx
        run: |
          echo "SQLX_OFFLINE=true" >> $GITHUB_ENV
      
      # Verify that sqlx-data.json is up-to-date and present
      - name: Verify SQLx metadata
        run: |
          if [ ! -f sqlx-data.json ]; then
            echo "Error: sqlx-data.json not found"
            echo "Run 'cargo sqlx prepare' locally and commit the file"
            exit 1
          fi
          
          # Also check if metadata matches current queries using temporary database
          mkdir -p .sqlx
          touch .sqlx/test.db
          
          # Apply migrations to test database to create schema
          cargo sqlx migrate run --database-url sqlite:.sqlx/test.db
          
          # Check if prepare would generate the same file
          SQLX_DATABASE_URL=sqlite:.sqlx/test.db cargo sqlx prepare --check
      
      # Build the application
      - name: Build
        run: cargo build --release
      
      # Build Docker image
      - name: Build Docker image
        if: github.event_name != 'pull_request'
        run: |
          docker build -t myapp:${{ github.sha }} .
      
      # Deploy (only on main branch push)
      - name: Deploy
        if: github.event_name == 'push' && github.ref == 'refs/heads/main'
        env:
          DB_PATH: ${{ secrets.DB_PATH }}
        run: |
          # Deploy with the real database path from secrets
          echo "Deploying with database at: $DB_PATH"
          # Your deployment commands here
```

## Deployment Strategies

Before implementing any deployment strategy, it's crucial to understand that migrations must be run during deployment against the actual runtime database. SQLx's offline mode handles compilation, but your application still needs to execute migrations at startup.

### Strategy 1: SQLite with Absolute Path

For applications using SQLite with a specific database path on the deployment server:

```yaml
# Deployment step in GitHub Actions
- name: Deploy with Docker Compose
  env:
    DB_PATH: ${{ secrets.DB_PATH }}
  run: |
    echo "DATABASE_URL=sqlite:$DB_PATH" > .env
    docker-compose up -d
```

Docker Compose file:
```yaml
version: '3'
services:
  app:
    image: myapp:${GITHUB_SHA}
    env_file: .env
    volumes:
      # Mount the directory containing the database
      - /path/on/host:/data
```

### Strategy 2: PostgreSQL Connection

For applications using PostgreSQL:

```yaml
# Deployment step
- name: Deploy with PostgreSQL
  env:
    PG_USER: ${{ secrets.PG_USER }}
    PG_PASSWORD: ${{ secrets.PG_PASSWORD }}
    PG_HOST: ${{ secrets.PG_HOST }}
    PG_DB: ${{ secrets.PG_DB }}
  run: |
    echo "DATABASE_URL=postgres://$PG_USER:$PG_PASSWORD@$PG_HOST/$PG_DB" > .env
    docker-compose up -d
```

### Strategy 3: Database Switching Pattern

For applications that need to support both SQLite and PostgreSQL:

```rust
// database.rs
use sqlx::{Any, AnyPool};
use std::env;

pub async fn create_pool() -> Result<AnyPool, sqlx::Error> {
    let db_type = env::var("DB_TYPE").unwrap_or_else(|_| "sqlite".to_string());
    
    let database_url = match db_type.as_str() {
        "postgres" => {
            let user = env::var("PG_USER").expect("PG_USER must be set");
            let password = env::var("PG_PASSWORD").expect("PG_PASSWORD must be set");
            let host = env::var("PG_HOST").expect("PG_HOST must be set");
            let db = env::var("PG_DB").expect("PG_DB must be set");
            
            format!("postgres://{}:{}@{}/{}", user, password, host, db)
        },
        _ => {
            // Default to SQLite
            let path = env::var("DB_PATH").unwrap_or_else(|_| "./data.db".to_string());
            format!("sqlite:{}", path)
        }
    };
    
    sqlx::any::AnyPoolOptions::new()
        .max_connections(5)
        .connect(&database_url)
        .await
}
```

## Troubleshooting

### Common Issues and Solutions

#### 1. "Database connection refused during build"

**Problem**: Even with `sqlx-data.json`, you're getting database connection errors.

**Solution**: Ensure `SQLX_OFFLINE=true` is set in your environment:
```bash
# In CI
echo "SQLX_OFFLINE=true" >> $GITHUB_ENV

# In Dockerfile
ENV SQLX_OFFLINE=true
```

#### 2. "SQL query panicked: no such table"

**Problem**: SQLx offline mode validates queries, but doesn't validate that tables exist.

**Solution**: Ensure migrations run before your application starts:
```rust
// In your main.rs or similar
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Get database URL
    let database_url = std::env::var("DATABASE_URL")?;
    
    // Create pool
    let pool = sqlx::AnyPool::connect(&database_url).await?;
    
    // Run migrations
    sqlx::migrate!("./migrations")
        .run(&pool)
        .await?;
    
    // Start application
    // ...
    
    Ok(())
}
```

#### 3. "Unable to find sqlx-data.json"

**Problem**: SQLx can't find the metadata file.

**Solution**: Check the working directory in your CI/CD pipeline and ensure the file is committed to git.

#### 4. "Mismatched SQLx metadata"

**Problem**: Your queries have changed but `sqlx-data.json` wasn't updated.

**Solution**: Add a verification step in CI to ensure metadata is up-to-date:
```yaml
- name: Verify SQLx metadata
  run: |
    # Temporarily disable offline mode to check
    unset SQLX_OFFLINE
    
    # Create test database
    mkdir -p .sqlx
    touch .sqlx/test.db
    
    # Check if prepare would generate the same file
    SQLX_DATABASE_URL=sqlite:.sqlx/test.db cargo sqlx prepare --check
```

### Database Path Injection Techniques

For SQLite databases with paths that differ between build and runtime:

#### Technique 1: Environment Variable Substitution

```rust
let db_path = std::env::var("DB_PATH").unwrap_or_else(|_| "./default.db".to_string());
let database_url = format!("sqlite:{}", db_path);
```

#### Technique 2: Configuration with `config` Crate

```rust
use config::{Config, File, Environment};

fn load_config() -> Config {
    Config::builder()
        // Start with defaults
        .set_default("database.type", "sqlite").unwrap()
        .set_default("database.path", "./data.db").unwrap()
        // Load from file
        .add_source(File::with_name("config").required(false))
        // Override with environment variables
        .add_source(Environment::with_prefix("APP"))
        .build()
        .unwrap()
}

// Usage
let config = load_config();
let db_type = config.get_string("database.type").unwrap();
let db_path = config.get_string("database.path").unwrap();
```

#### Technique 3: Docker Bind Mount

For SQLite databases, use Docker volumes to mount the database file:

```yaml
# docker-compose.yml
services:
  app:
    image: myapp:latest
    environment:
      - DATABASE_URL=sqlite:/data/app.db
    volumes:
      - sqlite_data:/data

volumes:
  sqlite_data:
```

## Conclusion

Successfully integrating SQLx into CI/CD workflows requires understanding the unique challenges posed by compile-time query checking. By properly configuring offline mode and carefully managing database connections between build and runtime environments, you can maintain SQLx's safety benefits while enabling smooth automated deployments.

The key takeaways are:
1. Generate and commit `sqlx-data.json` for offline builds
2. Use environment variables to manage database connections
3. Separate build-time and runtime database configurations 
4. Ensure migrations run during deployment
5. Test your pipeline thoroughly to catch potential issues early

By following these practices, your Rust application can leverage SQLx's powerful features while maintaining a robust CI/CD pipeline.

---

[<- Back to Database ORM](./01-database-orm.md) | [Current: 02 - Migrations](./02-migrations.md) | [Next: Backup Documentation ->](./03-backup-documentation.md)

next: [02d - SQLx Conceptual Landscape](./02d-conceptual-landscape-SQLx.md)
