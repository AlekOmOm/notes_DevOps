# 01a. Logging Implementation 📝

[<- Back to Main Topic](./01-Logging.md) | [Next Sub-Topic: Logging in Docker ->](./01b-Logging-in-Docker.md)

## Overview

This note provides practical implementation details for setting up effective logging systems in your applications. We'll focus on configuring logging libraries, structuring log data, and integrating with various logging backends.

## Key Concepts

### Structured Logging

Traditional text-based logs are difficult to parse and analyze. Structured logging solves this by formatting logs as structured data (usually JSON):

```javascript
// Unstructured logging
console.log(`User ${userId} updated profile at ${new Date().toISOString()}`);

// Structured logging
logger.info('User updated profile', {
  userId: '123',
  timestamp: new Date().toISOString(),
  changes: ['email', 'name']
});
```

Benefits of structured logging:
- Easy to parse and filter
- Queryable fields
- Consistent format
- Machine-readable

### Logger Configuration in Node.js

Using Winston, a popular logging library for Node.js:

```javascript
const winston = require('winston');

// Define log format
const logFormat = winston.format.combine(
  winston.format.timestamp(),
  winston.format.errors({ stack: true }),
  winston.format.json()
);

// Create logger
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: logFormat,
  defaultMeta: { service: 'user-service' },
  transports: [
    // Write to files
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' })
  ]
});

// Add console output during development
if (process.env.NODE_ENV !== 'production') {
  logger.add(new winston.transports.Console({
    format: winston.format.combine(
      winston.format.colorize(),
      winston.format.simple()
    )
  }));
}

// Usage
logger.info('User logged in', { userId: '123' });
logger.error('Database connection failed', { error: err });
```

### Logger Configuration in Python

Using the standard `logging` module with structlog for structured logging:

```python
import logging
import structlog
import sys
import datetime

# Configure standard logging
logging.basicConfig(
    level=logging.INFO,
    format="%(message)s",
    stream=sys.stdout,
)

# Configure structlog
structlog.configure(
    processors=[
        structlog.stdlib.filter_by_level,
        structlog.stdlib.add_logger_name,
        structlog.stdlib.add_log_level,
        structlog.stdlib.PositionalArgumentsFormatter(),
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
        structlog.processors.UnicodeDecoder(),
        structlog.processors.JSONRenderer()
    ],
    context_class=dict,
    logger_factory=structlog.stdlib.LoggerFactory(),
    wrapper_class=structlog.stdlib.BoundLogger,
    cache_logger_on_first_use=True,
)

# Create logger
logger = structlog.get_logger()

# Usage
logger.info("user_login", user_id="123", source_ip="192.168.1.1")
logger.error("database_error", error="Connection refused", retry_count=3)
```

## Implementation Patterns

### Pattern 1: Centralized Logging with ELK Stack

The ELK stack (Elasticsearch, Logstash, Kibana) is a popular solution for centralized logging:

```javascript
// Winston configuration for ELK Stack
const { ElasticsearchTransport } = require('winston-elasticsearch');

const esTransport = new ElasticsearchTransport({
  level: 'info',
  clientOpts: {
    node: 'http://elasticsearch:9200',
    auth: {
      username: 'elastic',
      password: process.env.ES_PASSWORD
    }
  },
  indexPrefix: 'logs-app'
});

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  defaultMeta: { service: 'api-service' },
  transports: [
    new winston.transports.Console(),
    esTransport
  ]
});
```

**When to use this pattern:**
- For distributed systems with multiple services
- When you need advanced search capabilities
- For larger teams and applications
- When you need visualization and alerting based on logs

### Pattern 2: Cloud-Native Logging

For applications running in cloud environments, use cloud provider logging services:

```javascript
// AWS CloudWatch Logs with Winston
const { CloudWatchTransport } = require('winston-cloudwatch');

const cloudwatchTransport = new CloudWatchTransport({
  logGroupName: '/aws/lambda/my-service',
  logStreamName: `${process.env.NODE_ENV}-${new Date().toISOString().slice(0, 10)}`,
  awsRegion: 'us-east-1',
  messageFormatter: ({ level, message, ...meta }) => JSON.stringify({
    level,
    message,
    ...meta,
    environment: process.env.NODE_ENV
  })
});

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  defaultMeta: { service: 'api-service' },
  transports: [
    new winston.transports.Console(),
    cloudwatchTransport
  ]
});
```

**When to use this pattern:**
- For applications deployed in cloud environments
- When you want native integration with cloud services
- For serverless or container-based architectures
- When you need to reduce operational overhead

## Common Challenges and Solutions

### Challenge 1: Log Volume Management

High log volumes can cause performance issues and increased costs.

**Solution:**

```javascript
// Implement sampling for high-volume logs
function shouldSample(level, message, meta) {
  // Always log errors and warnings
  if (level === 'error' || level === 'warn') {
    return true;
  }
  
  // For high-volume endpoint logs, sample at 10%
  if (message === 'request_completed' && meta.path === '/api/high-volume-endpoint') {
    return Math.random() < 0.1; // 10% sampling rate
  }
  
  // Log everything else
  return true;
}

// Custom Winston transport with sampling
const samplingTransport = new winston.transports.Console({
  format: winston.format.json(),
  log(info, callback) {
    if (shouldSample(info.level, info.message, info)) {
      console.log(JSON.stringify(info));
    }
    callback();
  }
});

const logger = winston.createLogger({
  level: 'info',
  transports: [samplingTransport]
});
```

### Challenge 2: Correlation Across Services

In distributed systems, tracking related logs across services is challenging.

**Solution:**

```javascript
// Express middleware for request correlation
const { v4: uuidv4 } = require('uuid');
const cls = require('cls-hooked');

// Create a namespace for the correlation ID
const ns = cls.createNamespace('request-context');

function correlationMiddleware(req, res, next) {
  // Extract correlation ID from header or generate a new one
  const correlationId = req.headers['x-correlation-id'] || uuidv4();
  
  // Set response header
  res.setHeader('x-correlation-id', correlationId);
  
  // Store in continuation-local storage for this request
  ns.run(() => {
    ns.set('correlationId', correlationId);
    next();
  });
}

// Create a logger that automatically includes the correlation ID
function getLogger() {
  return winston.createLogger({
    level: 'info',
    format: winston.format.combine(
      winston.format.timestamp(),
      winston.format.json(),
      winston.format((info) => {
        // Add correlation ID from CLS if available
        const correlationId = ns.get('correlationId');
        if (correlationId) {
          info.correlation_id = correlationId;
        }
        return info;
      })()
    ),
    transports: [
      new winston.transports.Console()
    ]
  });
}

// Usage in Express app
app.use(correlationMiddleware);

// In request handlers
app.get('/api/resource', (req, res) => {
  const logger = getLogger();
  logger.info('Processing request', { path: req.path });
  
  // The correlation ID is automatically included
  
  res.json({ success: true });
});
```

## Practical Example

A complete logging implementation for a production Node.js application:

```javascript
// logger.js
const winston = require('winston');
require('winston-daily-rotate-file');
const { format } = winston;
const path = require('path');

// Define log directory
const logDir = process.env.LOG_DIR || 'logs';

// Define custom formats
const sanitizeData = format((info) => {
  // List of fields to sanitize
  const sensitiveFields = ['password', 'token', 'key', 'secret', 'credit_card'];
  
  // Clone the metadata to avoid modifying the original
  const sanitized = { ...info };
  
  // Helper function to recursively sanitize objects
  function sanitize(obj) {
    if (!obj || typeof obj !== 'object') return obj;
    
    Object.keys(obj).forEach(key => {
      const lowerKey = key.toLowerCase();
      
      // Check if the field should be sanitized
      if (sensitiveFields.some(field => lowerKey.includes(field))) {
        obj[key] = '[REDACTED]';
      } else if (typeof obj[key] === 'object') {
        // Recursively sanitize nested objects
        obj[key] = sanitize({ ...obj[key] });
      }
    });
    
    return obj;
  }
  
  // Sanitize all properties
  return sanitize(sanitized);
});

const errorStackFormat = format(info => {
  if (info.error && info.error instanceof Error) {
    info.error = {
      message: info.error.message,
      stack: info.error.stack,
      ...info.error
    };
  }
  return info;
});

// Define log formats
const consoleFormat = format.combine(
  format.colorize(),
  format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
  format.printf(
    ({ timestamp, level, message, ...metadata }) => {
      const metaString = Object.keys(metadata).length ? 
        `\n${JSON.stringify(metadata, null, 2)}` : '';
      return `${timestamp} ${level}: ${message}${metaString}`;
    }
  )
);

const fileFormat = format.combine(
  format.timestamp(),
  sanitizeData(),
  errorStackFormat(),
  format.json()
);

// Create file transports with rotation
const fileTransport = new winston.transports.DailyRotateFile({
  filename: path.join(logDir, 'application-%DATE%.log'),
  datePattern: 'YYYY-MM-DD',
  maxSize: '20m',
  maxFiles: '14d',
  format: fileFormat
});

const errorFileTransport = new winston.transports.DailyRotateFile({
  filename: path.join(logDir, 'error-%DATE%.log'),
  datePattern: 'YYYY-MM-DD',
  maxSize: '20m',
  maxFiles: '30d',
  level: 'error',
  format: fileFormat
});

// Configure the logger
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  defaultMeta: { 
    service: process.env.SERVICE_NAME || 'app',
    environment: process.env.NODE_ENV || 'development'
  },
  transports: [
    fileTransport,
    errorFileTransport
  ],
  // Handle uncaught exceptions
  exceptionHandlers: [
    new winston.transports.DailyRotateFile({
      filename: path.join(logDir, 'exceptions-%DATE%.log'),
      datePattern: 'YYYY-MM-DD',
      maxFiles: '30d',
      format: fileFormat
    })
  ],
  // Exit on unhandled exceptions
  exitOnError: false
});

// Add console transport in development
if (process.env.NODE_ENV !== 'production') {
  logger.add(new winston.transports.Console({
    format: consoleFormat
  }));
}

// Add request context handling
const cls = require('cls-hooked');
const ns = cls.createNamespace('app');

// Middleware for Express.js
const requestLogger = (req, res, next) => {
  // Generate or use existing correlation ID
  const correlationId = req.headers['x-correlation-id'] || require('uuid').v4();
  
  // Add to response headers
  res.setHeader('x-correlation-id', correlationId);
  
  // Save in continuation-local storage
  ns.bindEmitter(req);
  ns.bindEmitter(res);
  
  ns.run(() => {
    ns.set('correlationId', correlationId);
    ns.set('ip', req.ip);
    ns.set('userId', req.user ? req.user.id : 'anonymous');
    
    // Log request
    logger.info('HTTP request', {
      method: req.method,
      url: req.originalUrl,
      ip: req.ip,
      user: req.user ? req.user.id : 'anonymous',
      correlationId
    });
    
    // Capture response
    const start = Date.now();
    const originalEnd = res.end;
    
    res.end = function(...args) {
      const duration = Date.now() - start;
      
      // Log response
      logger.info('HTTP response', {
        method: req.method,
        url: req.originalUrl,
        statusCode: res.statusCode,
        duration,
        correlationId
      });
      
      originalEnd.apply(res, args);
    };
    
    next();
  });
};

// Get a logger with the current request context
function getContextLogger() {
  return {
    debug: (message, meta = {}) => {
      logger.debug(message, addContext(meta));
    },
    info: (message, meta = {}) => {
      logger.info(message, addContext(meta));
    },
    warn: (message, meta = {}) => {
      logger.warn(message, addContext(meta));
    },
    error: (message, meta = {}) => {
      logger.error(message, addContext(meta));
    }
  };
}

// Add context info to log metadata
function addContext(meta) {
  if (!ns.active) return meta;
  
  return {
    ...meta,
    correlationId: ns.get('correlationId'),
    ip: ns.get('ip'),
    userId: ns.get('userId')
  };
}

// Export the logger and middleware
module.exports = {
  logger,
  requestLogger,
  getContextLogger
};
```

## Usage Examples

### Basic Usage

```javascript
// app.js
const { logger } = require('./logger');

logger.info('Application starting');

try {
  // Application logic
  logger.info('Operation completed', { items: 5, duration: 123 });
} catch (error) {
  logger.error('Failed to complete operation', { error });
}
```

### With Express.js

```javascript
// app.js
const express = require('express');
const { logger, requestLogger, getContextLogger } = require('./logger');

const app = express();

// Apply logging middleware
app.use(requestLogger);

// Routes
app.get('/api/users', (req, res) => {
  const log = getContextLogger();
  
  log.info('Fetching users');
  
  // All logs in this request handler will have the context data
  
  res.json({ users: [] });
});

// Error handling
app.use((err, req, res, next) => {
  const log = getContextLogger();
  
  log.error('Unhandled exception', { error: err });
  
  res.status(500).json({ error: 'Internal server error' });
});

// Start server
app.listen(3000, () => {
  logger.info('Server started', { port: 3000 });
});
```

## Summary

1. Structured logging provides consistent, machine-readable logs that are easier to analyze
2. Context correlation is critical in distributed systems to track requests across services
3. Log rotation and management prevents disk space issues and makes logs easier to maintain
4. Sanitization of sensitive data is essential for security and compliance
5. In production environments, centralized logging provides better visibility and analysis options

## Next Steps

Now that you've implemented a robust logging system, explore how to handle logging in containerized environments with Docker, where log persistence and centralization present unique challenges.

---

[<- Back to Main Topic](./01-Logging.md) | [Next Sub-Topic: Logging in Docker ->](./01b-Logging-in-Docker.md)