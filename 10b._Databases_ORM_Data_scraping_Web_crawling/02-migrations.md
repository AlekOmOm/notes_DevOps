# 2. Migrations 📝

[<- Back to Database ORM](./01-database-orm.md) | [Next: Backup Documentation ->](./03-backup-documentation.md)

## Table of Contents
- [What is a Migration?](#what-is-a-migration)
- [Types of Migrations](#types-of-migrations)
- [Migration Benefits](#migration-benefits)
- [Practical Migration with Knex.js](#practical-migration-with-knexjs)
- [Data Migration: Seeding](#data-migration-seeding)

## What is a Migration?

A migration is a programmatic way to define changes to a database schema, allowing for:
- Version control of database structure
- Consistent database state across environments
- Reproducible database setup
- Rollback capabilities for schema changes

Migrations serve as an alternative to maintaining a single SQL file for schema changes, providing a more structured and version-controlled approach.

## Types of Migrations

### 1. Schema Migration (DDL)
- Focuses on Data Definition Language operations
- Creates, alters, or drops database objects (tables, indexes, etc.)
- Example:
  ```javascript
  export function up(knex) {
    return knex.schema.createTable('users', (table) => {
      table.increments('id');
      table.string('email').unique().notNullable();
      table.string('name');
    });
  }
  
  export function down(knex) {
    return knex.schema.dropTable('users');
  }
  ```

### 2. Data Migration / Seeding (DML)
- Focuses on Data Manipulation Language operations
- **Data Migration**: Moves or transforms data between database structures
  - Usually refers to transferring data from one database to another
- **Seeding**: Populates a database with initial or test data
  - Generally used for new databases or for testing

Both types are commonly referred to simply as "migrations" despite their different purposes.

## Migration Benefits

1. **Schema Evolution**
   - Track and implement database changes over time
   - Synchronize schema changes among team members
   - Apply changes consistently across environments (dev, staging, production)

2. **Data Transformation**
   - Migrate data between different database systems
   - Transform existing data to match new schemas
   - Batch operations for large-scale data changes

3. **Consistency & Reliability**
   - Ensure database structure is identical across environments
   - Reduce "works on my machine" problems
   - Provide audit trail of database changes

4. **Recovery & Rollback**
   - Revert to previous database states when needed
   - Recover from failed deployments or migrations
   - Test migration procedures before production deployment

## Practical Migration with Knex.js

Knex.js provides a robust migration system for Node.js applications.

### Setup Process

1. **Environment Configuration**
   ```
   // .env file
   POSTGRES_DB=mydatabase
   POSTGRES_USER=myuser
   POSTGRES_PASSWORD=mypassword
   POSTGRES_HOST=localhost
   ```

2. **Database Container (Docker)**
   ```yaml
   # docker-compose.yml
   services:
     db:
       image: postgres:latest
       env_file:
         - .env
       ports:
         - "5432:5432"
       volumes:
         - postgres_data:/var/lib/postgresql/data
   
   volumes:
     postgres_data:
   ```

3. **Initialize Knex Project**
   ```bash
   npm init -y
   npm install knex pg dotenv
   npx knex init
   ```

4. **Configure Knex**
   ```javascript
   // knexfile.js
   import 'dotenv/config';
   
   export default {
     client: 'postgresql',
     connection: {
       database: process.env.POSTGRES_DB,
       user: process.env.POSTGRES_USER,
       password: process.env.POSTGRES_PASSWORD,
       host: process.env.POSTGRES_HOST,
     },
     migrations: {
       tableName: 'knex_migrations'
     }
   };
   ```

### Creating and Running Migrations

1. **Generate Migration File**
   ```bash
   npx knex migrate:make create_users_products_table
   ```

2. **Implement Migration Logic**
   ```javascript
   // Migration file
   export function up(knex) {
     return knex.schema
       .createTable('users', (table) => {
         table.increments('id');
         table.string('first_name', 255).notNullable();
         table.string('last_name', 255).notNullable();
       })
       .createTable('products', (table) => {
         table.increments('id');
         table.decimal('price').notNullable();
         table.string('name', 1000).notNullable();
       });
   }
   
   export function down(knex) {
     return knex.schema
       .dropTable('products')
       .dropTable('users');
   }
   ```

3. **Run Migration**
   ```bash
   npx knex migrate:latest
   ```

4. **Rollback If Needed**
   ```bash
   npx knex migrate:rollback
   ```

## Data Migration: Seeding

Seeding is the process of adding initial or test data to a database.

### Creating and Running Seeds with Knex

1. **Generate Seed File**
   ```bash
   npx knex seed:make seed_users
   ```

2. **Implement Seed Logic**
   ```javascript
   export async function seed(knex) {
     // Clear existing entries
     await knex('users').del();
   
     // Insert seed entries
     await knex('users').insert([
       { id: 1, first_name: 'John', last_name: 'Doe' },
       { id: 2, first_name: 'Jane', last_name: 'Smith' },
       { id: 3, first_name: 'Alice', last_name: 'Johnson' }
     ]);
   }
   ```

3. **Run Seeds**
   ```bash
   npx knex seed:run
   ```

### When to Use Seeding

- Creating admin or default users
- Populating reference or lookup tables
- Setting up test environments
- Demo or development data preparation
- Benchmarking with realistic data volumes

---

[<- Back to Database ORM](./01-database-orm.md) | [Next: Backup Documentation ->](./03-backup-documentation.md)
