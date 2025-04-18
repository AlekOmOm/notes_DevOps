# 2d. Conceptual Landscape of SQLx 🧩

[<- Back to Database ORM](./01-database-orm.md) | [Current: 02 - Migrations](./02-migrations.md) |  [Next: Backup Documentation ->](./03-backup-documentation.md)


---
- [02a - Migrations GitHub Actions](./02a-migrations-github-actions.md)
- [02b - SQLx in Rust with Docker environment](./02b-sqlx-rust-docker.md)
- [02c - SQLx for CI/CD](./02c-sqlx-for-ci-cd.md)
- [02d - SQLx Conceptual landscape](./02d-sqlx-conceptual-landscape.md)
---


## Table of Contents
- [2d. Conceptual Landscape of SQLx 🧩](#2d-conceptual-landscape-of-sqlx-)
  - [Table of Contents](#table-of-contents)
  - [Understanding SQLx](#understanding-sqlx)
  - [SQLx Integration with Actix](#sqlx-integration-with-actix)
  - [SQLx in Docker with SQLite](#sqlx-in-docker-with-sqlite)
  - [SQLx in Docker with PostgreSQL](#sqlx-in-docker-with-postgresql)
  - [Conceptual Summary](#conceptual-summary)

## Understanding SQLx

**What is SQLx? (The Smart Power Tool)**

SQLx is *not* an ORM (like Objection.js or SQLAlchemy). It's a **Rust SQL toolkit** focused on **compile-time safety** and **asynchronous execution**.

**Core Idea:** Instead of just sending raw SQL strings to the database at runtime and hoping they're correct, SQLx *verifies your SQL queries against your actual database schema during compilation*.

**How it Works (Conceptually):**
- You write SQL queries (often using macros like `sqlx::query!`).
- During `cargo build`, SQLx connects to a database specified by `DATABASE_URL`.
- It analyzes your SQL syntax.
- It asks the database: "Does this table exist? Do these columns exist? Are the parameter types ($1, $2, ?) compatible? What types will the result columns have?"
- If everything checks out, it generates highly optimized, type-safe Rust code to execute that query. If not, you get a *compile-time error*, not a runtime crash.

**Philosophical Angle:** SQLx prioritizes **correctness and safety** by shifting error detection from runtime (when your users might see it) to compile-time (when the developer sees it). It trades a bit of build-time complexity (needing DB access) for runtime robustness. It respects SQL, letting you write it directly, but adds a layer of Rust-based verification.

## SQLx Integration with Actix

**Concept:** Actix is your web framework (handling HTTP requests/responses, routing, middleware). SQLx is your specialized tool for database interaction within that framework.

**Integration Pattern:**
- **Connection Pool:** You typically create a `sqlx::Pool` when your Actix application starts. This pool manages a set of database connections efficiently.
- **Sharing the Pool:** This pool is shared with your Actix route handlers, often using Actix's application data mechanism (`web::Data<sqlx::Pool<Db>>`).
- **Executing Queries:** Inside your route handlers (which are usually `async fn`), you acquire a connection from the pool and use SQLx's functions/macros (`query!`, `query_as!`, `fetch_one`, `fetch_all`, etc.) to interact with the database. These operations are `async` and integrate naturally with Actix's asynchronous nature.

**SQLite vs. PostgreSQL:** From the *Actix code's perspective*, using SQLx is very similar for both. You initialize the pool differently (using the appropriate connection string) and might use slightly different SQL syntax, but the SQLx methods (`fetch`, `execute`, etc.) and the way you integrate the pool into Actix remain largely the same thanks to SQLx's database-agnostic traits (like `sqlx::Executor`). SQLx handles the driver-specific details behind the scenes.

**Philosophical Angle:** Actix provides the structure for your web service; SQLx provides the safe and efficient interface to the persistent data store. They are complementary tools, well-suited because both embrace Rust's async ecosystem.

## SQLx in Docker with SQLite

**The Core Challenge:** SQLx's compile-time check needs a database. For SQLite, the database is a *file* (`whoknows.db`).

**Build Time (GitHub Actions Runner):**
- When `docker build` runs, it executes `cargo build`. SQLx wants to connect to `DATABASE_URL`.
- Your `.db` file isn't in git, so it's not copied into the Docker build context. `DATABASE_URL` can't point to a non-existent file.
- Even if you *could* point it to a file, which one? The *developer's* local `dev.db`? That might have a different schema than production.

**Runtime (Deployment Server):**
- When `docker run` executes, the container starts. *Now* you want it to use the *real* database file located at an absolute path on the deployment server (e.g., `/srv/data/whoknows.db`). This path is stored in `secrets.DB_PATH`.

**Docker's Role:**
- **Image Build:** Docker follows the `Dockerfile` instructions to create a static image. This includes running `cargo build`.
- **Container Runtime:** Docker runs a container from the image. It allows you to:
  - Inject **environment variables** (`-e DATABASE_URL=...`).
  - Mount **volumes** (`-v /srv/data:/data_in_container`), linking a host directory to a container directory.

**Bridging the Gap (The Solutions):**
- **SQLx Offline Mode:** This is the key. You run `cargo sqlx prepare` *during development* against your dev DB. This creates `sqlx-data.json` (which *is* checked into git). During the Docker build (`cargo build`), you set `ENV SQLX_OFFLINE=true`. SQLx now uses `sqlx-data.json` for its compile-time checks instead of needing a live database connection. The build succeeds without needing the `.db` file.
- **Runtime Configuration:** When you run the container (`docker run`), you set the `DATABASE_URL` environment variable to point to the *actual* location of the database file *within the container's filesystem*, which is often mapped via a volume. E.g., `docker run -v /srv/data:/appdata -e DATABASE_URL="sqlite:/appdata/whoknows.db" your-image`. Your Rust code reads this `DATABASE_URL` at runtime to connect.

**Philosophical Angle:** You decouple the **build-time schema validation** (using pre-generated, version-controlled metadata - `sqlx-data.json`) from the **runtime database connection** (using environment variables and volumes pointing to the live data). Docker facilitates this separation between the static build artifact (image) and the dynamic runtime environment (container).

## SQLx in Docker with PostgreSQL

**Key Difference:** PostgreSQL is a server, accessed over the network, not a local file.

**The Challenge:** The core challenge of needing DB access during `cargo build` remains.

**Docker's Role:** Similar to SQLite, but network connectivity becomes central.

**Image Build:**
- **Option 1 (Offline Mode):** Same as SQLite. Generate `sqlx-data.json` against a dev PostgreSQL DB, commit it, build with `SQLX_OFFLINE=true`. This is often the simplest for CI.
- **Option 2 (Live DB during Build):** You *could* have the Docker build connect to a *real* PostgreSQL instance (maybe a temporary one spun up just for the build in CI, or a shared dev instance). `DATABASE_URL` would be `postgres://user:pass@host:port/db`. This avoids `sqlx-data.json` but requires network access during build.

**Container Runtime:**
- The container needs the connection string (`DATABASE_URL`) for the *runtime* PostgreSQL server. This is passed as an environment variable: `docker run -e DATABASE_URL="postgres://prod_user:secret@prod_db_host:5432/prod_db" your-image`.
- If the PostgreSQL database is *also* running in a Docker container (common with Docker Compose), Docker's internal networking allows your application container to reach the database container using its service name (e.g., `DATABASE_URL="postgres://user:pass@db:5432/app_db"` where `db` is the service name in `docker-compose.yml`).

**Philosophical Angle:** The network-based nature of PostgreSQL makes the *runtime* connection conceptually simpler in Docker (just point to the host/port). However, the *build-time* requirement still needs addressing, often using the same offline mode strategy as SQLite to keep builds self-contained and independent of external database availability. The core principle of separating build-time validation from runtime connection remains.

## Conceptual Summary

SQLx provides compile-time safety by checking queries against a database schema *during the build*. This creates a challenge in containerized environments (like Docker builds in CI) where the runtime database isn't typically available.

- For **SQLite** (file-based), the challenge involves the physical absence of the `.db` file during build and configuring the correct file path at runtime.
- For **PostgreSQL** (network-based), the challenge involves network accessibility to a database server during build and configuring the correct connection string at runtime.

The **SQLx offline mode** (`sqlx-data.json` + `SQLX_OFFLINE=true`) is the primary conceptual bridge, allowing builds to complete using pre-generated, version-controlled metadata, thus decoupling the build process from the need for a live database connection. Docker then handles the runtime configuration via environment variables and potentially volumes (especially for SQLite).

Understanding this build-time vs. runtime separation and how offline mode bridges it is key to using SQLx effectively in Dockerized CI/CD pipelines.

---

[<- Back to Migrations](./02-migrations.md) | [<- Back to SQLx CI/CD Workflow](./02c-sqlx-ci-cd-workflow.md)
