# 3. Backup Documentation 💾

[<- Back to Migrations](./02-migrations.md) | [Next: Web Scraping & Web Crawling ->](./04-web-scraping-web-crawling.md)

## Table of Contents
- [Database Backup Strategies](#database-backup-strategies)
- [PostgreSQL Dumps](#postgresql-dumps)
- [MySQL Dumps](#mysql-dumps)
- [Database Persistence in Docker](#database-persistence-in-docker)
- [Database Initialization Scripts](#database-initialization-scripts)
- [Database Documentation Generation](#database-documentation-generation)

## Database Backup Strategies

Effective database backup is a critical component of any production system. A comprehensive backup strategy typically includes:

- **Regular scheduled backups** (hourly, daily, weekly)
- **Point-in-time recovery** (transaction logs)
- **On-demand backups** (before major changes)
- **Backup verification** (testing restoration)
- **Secure storage** (encryption, off-site copies)

Database dumps are a common backup method that captures the entire database state in a single file containing SQL statements to recreate the database structure and data.

## PostgreSQL Dumps

The `pg_dump` utility creates a consistent snapshot of a PostgreSQL database.

### Creating a PostgreSQL Dump

```bash
# Basic dump (from host)
pg_dump -h localhost -U username -d database_name > backup.sql

# For a Docker container
docker compose exec -T db pg_dump -U myuser mydatabase > pgdump.sql
```

### What the Dump File Contains

A PostgreSQL dump file typically contains:
- **DDL statements** (CREATE TABLE, CREATE INDEX, etc.)
- **DML statements** (INSERT, etc.) for data
- **DCL statements** (GRANT, etc.) for permissions

### Restoring from a PostgreSQL Dump

```bash
# Basic restore (from host)
psql -h localhost -U username -d database_name < backup.sql

# For a Docker container
PGPASSWORD=mypassword psql -U myuser -h 127.0.0.1 -d mydatabase < pgdump.sql
```

## MySQL Dumps

The `mysqldump` utility creates exports of MySQL databases.

### Creating a MySQL Dump

```bash
# Basic dump
mysqldump -u username -p database_name > backup.sql

# With additional options
mysqldump -u username -p --opt --single-transaction database_name > backup.sql
```

### Restoring from a MySQL Dump

```bash
mysql -u username -p database_name < backup.sql
```

## Database Persistence in Docker

When using Docker for database services, data persistence is managed through volumes.

### Volume Configuration

```yaml
# docker-compose.yml
services:
  db:
    image: postgres:latest
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

### Managing Docker Volumes

```bash
# List volumes
docker volume ls

# Remove volumes (caution: destroys data)
docker compose down -v

# Create a clean database state
docker compose down -v
docker compose up
```

The `-v` flag with `docker compose down` removes the defined volumes, giving you a clean state for the next startup.

## Database Initialization Scripts

Docker database images can automatically execute SQL scripts during container initialization.

### Adding Initialization Scripts

1. Create an initialization directory:
   ```bash
   mkdir initdb
   ```

2. Place SQL scripts in the directory:
   ```bash
   # Move your dump file to the initialization directory
   mv pgdump.sql ./initdb/init.sql
   ```

3. Add the directory as a volume in your Docker Compose file:
   ```yaml
   services:
     db:
       image: postgres:latest
       volumes:
         - postgres_data:/var/lib/postgresql/data
         - ./initdb/init.sql:/docker-entrypoint-initdb.d/init.sql
   ```

The database container will automatically execute all `.sql`, `.sh`, and `.sql.gz` files in the `/docker-entrypoint-initdb.d/` directory during initialization.

### Important Notes

- Scripts are only executed when the database is first initialized (empty data directory)
- Scripts run in alphabetical order
- For large databases, initialization may take significant time

## Database Documentation Generation

Documenting your database schema is crucial for team understanding and maintenance.

### MRO (Model Relations to Objects)

MRO is a utility that generates documentation from existing database schemas.

```bash
# Install and run MRO
npx mro
```

MRO provides several output options:

1. **Knex.js Migrations**: Reverse-engineer existing databases into migration files
   ```bash
   npx mro
   # Choose "Knex.js Migrations" when prompted
   ```

2. **HTML Documentation**: Generate browsable documentation
   ```bash
   npx mro
   # Choose "HTML documentation" when prompted
   ```

### Other Documentation Methods

Different database types have specific documentation approaches:

- **Relational Databases**: 
  - ER Diagrams
  - Schema visualizers (e.g., pgAdmin's schema visualization)
  - Auto-generated documentation (e.g., SchemaSpy)

- **NoSQL Databases**:
  - JSON Schema documents
  - HTML documentation of document structures
  - Example document collections

- **Graph Databases**:
  - GraphML exports
  - Graphviz visualizations
  - Schema diagrams

---

[<- Back to Migrations](./02-migrations.md) | [Next: Web Scraping & Web Crawling ->](./04-web-scraping-web-crawling.md)