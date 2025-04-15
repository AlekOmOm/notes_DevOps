# 03. Search Implementation 🔍

[<- Back to Monitoring](./02-Monitoring.md) | [Next: Web Crawling ->](./04-Crawling.md)

## Table of Contents

- [Introduction](#introduction)
- [SQLite with FTS5](#sqlite-with-fts5)
- [PostgreSQL Text Search](#postgresql-text-search)
- [Vector Databases](#vector-databases)
- [Performance Considerations](#performance-considerations)
- [Search Relevance and Ranking](#search-relevance-and-ranking)
- [Best Practices](#best-practices)

## Introduction

Effective search functionality is crucial for modern applications, allowing users to find relevant information quickly. This note covers different approaches to implementing search features, focusing on database-native search capabilities and specialized search technologies.

Search implementation varies based on application needs, database technology, and performance requirements. We'll explore the most common approaches, from simple database queries to advanced search engines.

## SQLite with FTS5

SQLite's Full-Text Search (FTS5) extension provides powerful search capabilities for lightweight applications.

### Key Concepts

- **Tokenization**: FTS5 breaks down the text into searchable words
- **Indexing**: Creates an index with document ID, column index, and token offset
- **Performance**: Much faster than the `LIKE` operator due to specialized indexing
- **Scoring**: Uses BM25 algorithm for result ranking

### Implementation Example

```sql
-- Creating an FTS5 virtual table
CREATE VIRTUAL TABLE pages_fts USING fts5(
  title, 
  content,
  tokenize='porter'
);

-- Inserting data
INSERT INTO pages_fts (title, content) 
VALUES ('Introduction to SQLite', 'SQLite is a lightweight database...');

-- Searching with the MATCH operator
SELECT * FROM pages_fts 
WHERE pages_fts MATCH 'sqlite database' 
ORDER BY rank;
```

The `MATCH` operator performs significantly better than `LIKE` because it uses the FTS index rather than scanning all rows sequentially.

## PostgreSQL Text Search

PostgreSQL offers robust text search through its `tsvector` and `tsquery` types.

### Setting Up Text Search

```sql
-- Adding a column for the search vector
ALTER TABLE pages ADD COLUMN content_tsv tsvector;

-- Populating the search vector with English stemming
UPDATE pages SET content_tsv = to_tsvector('english', content);

-- Creating a GIN index for performance
CREATE INDEX content_tsv_idx ON pages USING GIN(content_tsv);
```

### Automating Updates with Triggers

```sql
-- Setting up automatic updates via trigger
CREATE FUNCTION update_content_tsv() RETURNS trigger AS $$
BEGIN
    NEW.content_tsv := to_tsvector('english', NEW.content);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tsvector_update BEFORE INSERT OR UPDATE
ON pages FOR EACH ROW EXECUTE FUNCTION update_content_tsv();
```

### Query Example

```sql
-- Basic search query
SELECT * FROM pages
WHERE content_tsv @@ plainto_tsquery('english', 'search terms')
ORDER BY ts_rank(content_tsv, plainto_tsquery('english', 'search terms')) DESC;
```

PostgreSQL's text search capabilities include:
- **Language-aware stemming**: Recognizes word variations (run, running, ran)
- **Stop word removal**: Ignores common words like "the", "and", "is"
- **Ranking**: Orders results by relevance
- **Advanced query operators**: Allows phrase searches, negation, and proximity searches

## Vector Databases

For semantic search capabilities, vector databases store and query high-dimensional vectors representing semantic meaning.

### Vector Search Concepts

- **Embeddings**: Convert text/images into numerical vectors capturing semantic meaning
- **Similarity search**: Find items with similar meaning, not just matching keywords
- **Integration**: Can complement traditional databases by handling the search aspect

### Options for Vector Search

1. **PostgreSQL with pgvector extension**:
   ```sql
   -- Install the extension
   CREATE EXTENSION vector;
   
   -- Create a table with vector column
   CREATE TABLE items (
     id bigserial PRIMARY KEY,
     embedding vector(384),  -- For example, using 384-dimensional embeddings
     content text
   );
   
   -- Create an index for similarity search
   CREATE INDEX ON items USING ivfflat (embedding vector_l2_ops);
   
   -- Query for similar items
   SELECT content, embedding <-> $1 as distance
   FROM items
   ORDER BY distance
   LIMIT 5;
   ```

2. **Dedicated Vector Databases**:
   - **Pinecone**: Managed vector database service
   - **Milvus**: Open-source vector database
   - **Weaviate**: Knowledge graph with vector search
   - **Qdrant**: Vector database focusing on extended filtering

## Performance Considerations

When implementing search functionality, consider these performance factors:

### Indexing Performance

- **Index size**: Text indices can grow large, requiring sufficient storage
- **Index update cost**: Updates to indexed fields require index rebuilding
- **Batch indexing**: For large datasets, batch updates are more efficient

### Query Performance

- **Index type**: Different index types (B-tree, hash, GIN, etc.) have different performance characteristics
- **Caching**: Frequently-used search results can be cached
- **Query complexity**: Complex queries with multiple conditions are slower
- **Result pagination**: Limit result sets and use pagination for better performance

Example of optimizing a PostgreSQL search query:

```sql
-- Optimized search with pagination
SELECT id, title, ts_headline('english', content, plainto_tsquery('english', 'search terms')) as snippet
FROM pages
WHERE content_tsv @@ plainto_tsquery('english', 'search terms')
ORDER BY ts_rank(content_tsv, plainto_tsquery('english', 'search terms')) DESC
LIMIT 10 OFFSET 0;
```

## Search Relevance and Ranking

Ensuring that the most relevant results appear first is critical for user satisfaction.

### Relevance Factors

1. **Term frequency**: How often search terms appear in the document
2. **Field weighting**: Giving higher priority to matches in important fields (e.g., title)
3. **Recency**: More recent documents may be more relevant
4. **Popularity**: Documents viewed more often may be more relevant

### Implementing Relevance in PostgreSQL

```sql
-- Using weights in PostgreSQL to prioritize title matches
SELECT id, title, content, 
ts_rank(
  setweight(to_tsvector('english', title), 'A') || 
  setweight(to_tsvector('english', content), 'B'),
  plainto_tsquery('english', 'search terms')
) AS rank
FROM pages 
WHERE to_tsvector('english', title) || to_tsvector('english', content) @@ 
      plainto_tsquery('english', 'search terms')
ORDER BY rank DESC;
```

### Handling Typos and Variations

```sql
-- Using trigram similarity in PostgreSQL
-- First, add the pg_trgm extension
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Then create an index
CREATE INDEX pages_title_trgm_idx ON pages USING gin (title gin_trgm_ops);

-- Search with similarity
SELECT id, title, content, similarity(title, 'serch') AS sim
FROM pages
WHERE title % 'serch'
ORDER BY sim DESC
LIMIT 10;
```

## Best Practices

1. **Choose the right technology**:
   - For small applications with simple needs, use database-native search
   - For complex search requirements, consider dedicated search engines

2. **Optimize indexing**:
   - Index only what you need to search
   - Update indices efficiently, possibly asynchronously
   - Use appropriate index types for your data

3. **Enhance user experience**:
   - Implement autocomplete/suggestions
   - Provide faceted search for filtering
   - Highlight matching terms in results
   - Use pagination for large result sets

4. **Monitor and improve**:
   - Track search performance metrics
   - Analyze failed searches to improve
   - Tune relevance based on user behavior

5. **Consider hybrid approaches**:
   - Combine keyword search with semantic search
   - Use different technologies for different search types

For more detailed implementation specifics, see:
- [03a. Advanced PostgreSQL Search](./03a-Advanced-PostgreSQL-Search.md)
- [03b. Vector Search Implementation](./03b-Vector-Search-Implementation.md)

---

[<- Back to Monitoring](./02-Monitoring.md) | [Next: Web Crawling ->](./04-Crawling.md)
