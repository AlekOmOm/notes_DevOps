# 3. Express.js Backend ⚡

[<- Back to Main Note](./README.md) | [Previous: Svelte Frontend](./02-svelte-frontend.md) | [Next: Session Management ->](./04-session-management.md)

## Table of Contents

- [Express.js Setup](#expressjs-setup)
- [Server Configuration](#server-configuration)
- [Router Implementation](#router-implementation)
- [Middleware Configuration](#middleware-configuration)
- [Error Handling](#error-handling)

## Express.js Setup

Express.js is a minimal and flexible Node.js web application framework that provides a robust set of features for web and mobile applications. In the Medicine project, it serves as the backend framework.

### Project Initialization

The server is set up as an independent Node.js project with its own package.json:

```json
{
  "name": "server",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "keywords": [],
  "author": "",
  "license": "ISC",
  "type": "module",
  "dependencies": {
    "cors": "^2.8.5",
    "dotenv": "^16.5.0",
    "express": "^5.1.0",
    "express-session": "^1.18.1"
  }
}
```

Key points:
- Using ECMAScript modules with `"type": "module"`
- Express.js 5.1.0 (latest version)
- Dependencies for CORS, environment variables, and session management

## Server Configuration

The server is configured in the `app.js` file, which sets up the Express application and wires everything together:

```javascript
import 'dotenv/config';
import express from 'express';

const app = express();

app.use(express.json());

// CORS configuration
app.use((req, res, next) => {
	res.header("Access-Control-Allow-Origin", req.headers.origin || "*");
	res.header("Access-Control-Allow-Credentials", "true");
	res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
	next();
});

// Session configuration
import session from 'express-session';

app.use(session({
    secret: process.env.SESSION_SECRET,
    resave: false,
    saveUninitialized: true,
    cookie: { secure: false }
}));

// Router imports
import employeesRouter from './routers/employeesRouter.js';
app.use(employeesRouter);
import pillsRouter from './routers/pillsRouter.js';
app.use(pillsRouter);

// Start server
const PORT = Number(process.env.PORT) || 8080;
app.listen(PORT, () => console.log("Server is running on port", PORT));
```

This configuration:
1. Sets up middleware for JSON parsing and CORS
2. Configures session management
3. Registers routers for different API domains
4. Starts the server on the specified port

## Router Implementation

The Express application uses the Router pattern to organize routes by domain:

### Employee Router

```javascript
// employeesRouter.js
import { Router } from 'express';

const router = Router();

const employees = ["Ilmer", "Homer"];

router.get("/employees", (req, res) => {
    res.send({ data: employees });
});

export default router;
```

### Pills Router

```javascript
// pillsRouter.js
import { Router } from 'express';

const router = Router();

router.get("/pills", (req, res) => {
    res.send({ data: req.session.pills || [] });
});

router.post("/pills", (req, res) => {
    if (!req.session.pills) {
        req.session.pills = [];
    }
    req.session.pills.push(req.body);

    res.send({ data: req.session.pills });
});

export default router;
```

Benefits of this approach:
- Modular code organization by domain or resource
- Easier to maintain and extend
- Clear separation of concerns
- Simplified testing

## Middleware Configuration

Express.js middleware functions are functions that have access to the request object, the response object, and the next middleware function in the application's request-response cycle.

### Built-in Middleware

```javascript
// Parse JSON requests
app.use(express.json());
```

### Custom CORS Middleware

```javascript
app.use((req, res, next) => {
    res.header("Access-Control-Allow-Origin", req.headers.origin || "*");
    res.header("Access-Control-Allow-Credentials", "true");
    res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
    next();
});
```

### Session Middleware

```javascript
app.use(session({
    secret: process.env.SESSION_SECRET,
    resave: false,
    saveUninitialized: true,
    cookie: { secure: false }
}));
```

The middleware stack in Express executes in the order it's defined, so the sequence of middleware registration is important.

## Error Handling

While not explicitly implemented in the current project, proper Express.js applications should include error handling:

### Global Error Handler

A best practice (that could be added):

```javascript
// Error handling middleware (should be last in the chain)
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).send({
    message: 'Something went wrong!',
    error: process.env.NODE_ENV === 'production' ? {} : err
  });
});
```

### Route-Level Error Handling

Individual routes can include try/catch blocks:

```javascript
router.get("/pills", async (req, res, next) => {
    try {
        // Async operations that might fail
        res.send({ data: req.session.pills || [] });
    } catch (error) {
        next(error); // Pass to error handling middleware
    }
});
```

## Server-Side Rendering Variant

The project includes a second server implementation in the `serverSSR` directory that adds server-side rendering capabilities:

```javascript
// serverSSR/app.js
import 'dotenv/config';
import express from 'express';
import path from 'path';

const app = express();

app.use(express.json());
app.use(express.static(path.resolve('../client/dist/')));

// ... session and router configuration ...

// Fallback route for SPA
app.get("/{*splat}", (req, res) => {
  res.sendFile(path.resolve('../client/dist/index.html'));
});

const PORT = Number(process.env.PORT) || 8080;
app.listen(PORT, () => console.log("Server is running on port", PORT));
```

Key differences:
1. Serves static files from the client build directory
2. Includes a wildcard route that sends the SPA index.html for client-side routing
3. Integrates both API and static file serving into a single server

This approach enables server-side rendering while maintaining the same API endpoints, allowing for a smooth transition between client-side and server-side rendering approaches.

---

[<- Back to Main Note](./README.md) | [Previous: Svelte Frontend](./02-svelte-frontend.md) | [Next: Session Management ->](./04-session-management.md)
