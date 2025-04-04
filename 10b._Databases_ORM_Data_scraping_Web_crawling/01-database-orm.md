# 1. Database ORM (Object-Relational Mapping) 🗄️

[<- Back to Main](./README.md) | [Next: Migrations ->](./02-migrations.md)

## Table of Contents
- [What is an ORM?](#what-is-an-orm)
- [ORM vs. Raw SQL](#orm-vs-raw-sql)
- [Choosing a Database](#choosing-a-database)
- [Popular ORM Solutions](#popular-orm-solutions)
- [When to Use/Not Use an ORM](#when-to-usenot-use-an-orm)

## What is an ORM?

Object-Relational Mapping (ORM) is a programming technique that converts data between incompatible type systems in relational databases and object-oriented programming languages.

An ORM acts as a bridge between:
- **Relational databases** (tables, rows, columns)
- **Object-oriented code** (classes, objects, properties)

The core function is to:
1. Create a virtual object database that can be used from within the programming language
2. Handle database operations through programming objects rather than direct SQL queries
3. Abstract away the underlying database implementation

```javascript
// Example: Using an ORM vs. raw SQL
// Raw SQL
const users = await db.query('SELECT * FROM users WHERE age > 18');

// Using an ORM (e.g., Objection.js)
const users = await User.query().where('age', '>', 18);
```

## ORM vs. Raw SQL

| Aspect | ORM | Raw SQL |
|--------|-----|---------|
| **Learning Curve** | Higher initial learning curve | Lower if SQL is known |
| **Development Speed** | Faster for standard operations | More verbose, requires writing queries |
| **Performance** | Can be slower for complex queries | Typically more efficient, optimizable |
| **Maintainability** | Code often more maintainable | Can become scattered and hard to manage |
| **Database Agnosticism** | Often supports multiple databases | Database-specific |
| **Type Safety** | Often provides type checking | No inherent type checking |
| **Control** | Less fine-grained control | Complete control over queries |

**Key Insight**: An ORM is either equal to or less efficient than writing raw SQL. ORMs are not inherently "more secure" - security depends on implementation.

## Choosing a Database

The most important criterion: **Choose what's right for your use case.**

- **SQLite**: Suitable for most web applications, especially when traffic volumes are moderate
- **PostgreSQL vs. MySQL**:
  - PostgreSQL is open-source; MySQL has proprietary elements
  - PostgreSQL offers better JSON support
  - PostgreSQL is increasingly preferred by developers ([Stack Overflow 2023 survey](https://survey.stackoverflow.co/2023/#section-most-popular-technologies-databases))
  - MySQL has historically been more widely used

**SQLite Advantages**:
- Self-contained, serverless, zero-configuration
- Reliable for applications with moderate concurrency needs
- Excellent for development, testing, and many production cases

## Popular ORM Solutions

### JavaScript/Node.js
- **Knex.js**: Query builder that provides a flexible, fluent API
- **Objection.js**: Built on Knex.js, adds an ORM layer
  ```javascript
  // Objection.js model example
  class Person extends Model {
    static get tableName() {
      return 'persons';
    }
    
    static get relationMappings() {
      return {
        pets: {
          relation: Model.HasManyRelation,
          modelClass: Animal,
          join: {
            from: 'persons.id',
            to: 'animals.ownerId'
          }
        }
      };
    }
  }
  ```
- **Prisma**: Modern ORM with strong TypeScript support
  ```javascript
  // Prisma model definition
  model User {
    id        Int      @id @default(autoincrement())
    email     String   @unique
    name      String?
    posts     Post[]
  }
  
  model Post {
    id        Int      @id @default(autoincrement())
    title     String
    content   String?
    published Boolean  @default(false)
    author    User     @relation(fields: [authorId], references: [id])
    authorId  Int
  }
  ```

### Python
- **SQLAlchemy**: The most widely used Python ORM
- **Django ORM**: Part of the Django framework
- **Peewee**: Lightweight alternative

### Java
- **Hibernate/JPA**: Industry standard for Java applications
- **Spring Data JPA**: Simplifies data access

## When to Use/Not Use an ORM

**Use an ORM when**:
- Building complex, long-term applications
- Working with a team that benefits from abstraction
- Database schema changes frequently
- Multiple database support is needed
- Learning or mastering a new programming paradigm

**Skip the ORM when**:
- Building small projects or MVPs with fixed deadlines
- Data operations are simple and well-defined
- Performance is critical for complex queries
- Team is more comfortable with SQL
- Project scope is limited with minimal expected changes

**Remember**: For educational purposes, implementing an ORM can be valuable for learning, even if it's not the optimal choice for a particular project.

---

[<- Back to Main](./README.md) | [Next: Migrations ->](./02-migrations.md)