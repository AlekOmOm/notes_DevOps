# 6. Client-Server Communication 🔌

[<- Back to Main Note](./README.md) | [Previous: Server-Side Rendering](./05-server-side-rendering.md)

## Table of Contents

- [Communication Patterns](#communication-patterns)
- [Fetch API Implementation](#fetch-api-implementation)
- [Environment Configuration](#environment-configuration)
- [CORS Considerations](#cors-considerations)
- [Error Handling](#error-handling)

## Communication Patterns

Client-server communication forms the backbone of modern web applications. In the Medicine project, HTTP-based API communication is used to exchange data between the Svelte frontend and Express.js backend.

### Request-Response Pattern

The primary pattern used is the traditional request-response model:

1. Client initiates a request to a specific endpoint
2. Server processes the request and performs necessary operations
3. Server returns a response with appropriate status code and data
4. Client processes the response and updates UI accordingly

This pattern is evident in the Pharmacy component's interaction with the pills API:

```javascript
// Client initiates request
async function fillPrescription() {
    // Send data to server
    fetchPost($BASE_URL+"/pills", {
        name: "Ibuprofen"
    });
    // Get updated data from server
    pills = (await fetchGet($BASE_URL+"/pills")).data;
}
```

### Data Format

The Medicine project uses JSON as the data interchange format:

```javascript
// Server response format in pillsRouter.js
router.get("/pills", (req, res) => {
    res.send({ data: req.session.pills || [] });
});

// Client processing in Pharmacy.svelte
pills = (await fetchGet($BASE_URL+"/pills")).data;
```

This consistent data structure with a `data` property simplifies client-side processing.

## Fetch API Implementation

The Medicine project implements a thin abstraction layer over the browser's Fetch API to standardize API calls.

### Utility Functions

In `src/util/fetch.js`, two utility functions encapsulate GET and POST requests:

```javascript
export async function fetchGet(url) {
    try {
        const response = await fetch(url, {
            credentials: "include"
        });
        const result = await response.json();
        return result;
    } catch (error) {
        console.log(error);
    }
}

export function fetchPost(url, body) {
    return fetch(url, {
        method: "POST",
        credentials: "include",
        headers: {
            "Content-Type": "application/json"
        },
        body: JSON.stringify(body)
    })
    .then((response) => response.json())
    .then((result) => result)
    .catch((error) => console.log(error));
}
```

Key features of this implementation:
- `credentials: "include"` ensures cookies (including session cookies) are sent
- Consistent error handling pattern
- Automatic JSON parsing of responses
- JSON serialization of request bodies

### Usage in Components

These utility functions are imported and used in components:

```javascript
// In Pharmacy.svelte
import { fetchGet, fetchPost } from "../../util/fetch.js";

onMount(async () => {
    pills = (await fetchGet($BASE_URL+"/pills")).data;
})

async function fillPrescription() {
    fetchPost($BASE_URL+"/pills", {
        name: "Ibuprofen"
    });
    pills = (await fetchGet($BASE_URL+"/pills")).data;
}
```

This approach provides several benefits:
- Consistent API interaction patterns
- Centralized configuration and error handling
- Easier to extend or modify (e.g., adding authentication headers)

## Environment Configuration

The Medicine project uses environment variables to manage configuration across different environments.

### Backend Configuration

The server uses `dotenv` to load environment variables:

```javascript
// In server/app.js
import 'dotenv/config';

// Later used for configuration
app.use(session({
    secret: process.env.SESSION_SECRET,
    // ...
}));

const PORT = Number(process.env.PORT) || 8080;
```

### Frontend Configuration

Vite provides built-in support for environment variables with the `import.meta.env` object:

```javascript
// In generalStore.js
import { readable } from "svelte/store";

export const BASE_URL = readable(import.meta.env.VITE_BASE_URL || "http://localhost:8080");
```

Environment variables in Vite must be prefixed with `VITE_` to be exposed to client-side code.

### Environment Variable Management

For a production application, you would typically have multiple `.env` files:

```
.env               # Default values, checked into version control
.env.local         # Local overrides, not checked into version control
.env.development   # Development-specific values
.env.production    # Production-specific values
```

## CORS Considerations

Cross-Origin Resource Sharing (CORS) is a security mechanism that restricts HTTP requests made from scripts to resources in a different domain.

### Server-Side CORS Configuration

The Medicine project implements a custom CORS middleware:

```javascript
// In server/app.js
app.use((req, res, next) => {
    res.header("Access-Control-Allow-Origin", req.headers.origin || "*");
    res.header("Access-Control-Allow-Credentials", "true");
    res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
    next();
});
```

Key points about this configuration:
- `Access-Control-Allow-Origin` set to the request origin (or `*` as fallback)
- `Access-Control-Allow-Credentials` set to `true` to allow cookies
- Specific headers allowed for cross-origin requests

In a more complex application, you might use the `cors` package for more flexible configuration:

```javascript
// Alternative using cors package (not in current project)
import cors from 'cors';

app.use(cors({
    origin: process.env.NODE_ENV === 'production' 
        ? 'https://production-domain.com' 
        : 'http://localhost:3000',
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
    allowedHeaders: ['Content-Type', 'Authorization']
}));
```

### Preflight Requests

For non-simple requests (e.g., with custom headers or methods other than GET/POST), browsers send a preflight OPTIONS request:

```javascript
// Handling preflight requests (would be needed for more complex APIs)
app.options('*', (req, res) => {
    res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE');
    res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    res.status(200).send();
});
```

## Error Handling

Robust error handling is essential for reliable client-server communication.

### Server-Side Error Handling

While not fully implemented in the current project, a comprehensive approach would include:

```javascript
// Route-level error handling
router.get("/pills", async (req, res, next) => {
    try {
        // API logic
        res.send({ data: req.session.pills || [] });
    } catch (error) {
        next(error); // Pass to error middleware
    }
});

// Global error middleware
app.use((err, req, res, next) => {
    console.error(`Error: ${err.message}`);
    
    const statusCode = err.statusCode || 500;
    const message = statusCode === 500 && process.env.NODE_ENV === 'production'
        ? 'Internal Server Error'
        : err.message;
    
    res.status(statusCode).json({
        error: {
            message,
            code: err.code || 'INTERNAL_ERROR'
        }
    });
});
```

### Client-Side Error Handling

The fetch utility functions include basic error catching:

```javascript
export async function fetchGet(url) {
    try {
        const response = await fetch(url, {
            credentials: "include"
        });
        const result = await response.json();
        return result;
    } catch (error) {
        console.log(error);
        // In a more robust implementation, we might:
        // - Return a standardized error object
        // - Display user-friendly error message
        // - Log to monitoring service
    }
}
```

A more comprehensive approach would include:

```javascript
// Enhanced fetch with better error handling (not in current project)
export async function enhancedFetch(url, options = {}) {
    try {
        const response = await fetch(url, {
            credentials: "include",
            ...options
        });
        
        // Check if status code indicates success
        if (!response.ok) {
            // Try to parse error response
            let errorData;
            try {
                errorData = await response.json();
            } catch (e) {
                errorData = { message: 'Unknown error' };
            }
            
            // Create error object with additional context
            const error = new Error(errorData.message || `Request failed with status ${response.status}`);
            error.status = response.status;
            error.data = errorData;
            throw error;
        }
        
        return await response.json();
    } catch (error) {
        // Log error
        console.error('API Error:', error);
        
        // Notify user - could dispatch to a notification system
        notifyUser(error.message || 'An error occurred while communicating with the server');
        
        // Maybe retry for certain errors
        if (error.status === 429 || error.status >= 500) {
            // Implement retry logic
        }
        
        // Rethrow or return standardized error object
        throw error;
    }
}
```

## Advanced Communication Patterns

For future development, the Medicine project could incorporate more advanced patterns:

### Real-Time Updates

Using WebSockets or Server-Sent Events (SSE) for real-time data:

```javascript
// Server-side (Express with Socket.io)
import { Server } from 'socket.io';
const io = new Server(server);

io.on('connection', (socket) => {
    console.log('Client connected');
    
    // Emit updates when data changes
    pillsRouter.on('pill-added', (data) => {
        socket.emit('pill-update', data);
    });
});

// Client-side (Svelte component)
import { io } from 'socket.io-client';

onMount(() => {
    const socket = io($BASE_URL);
    
    socket.on('pill-update', (data) => {
        pills = data;
    });
    
    return () => socket.disconnect();
});
```

### GraphQL Integration

For more complex data requirements, GraphQL could provide more efficient data fetching:

```javascript
// Client-side query (using a GraphQL client)
const GET_PILLS = `
  query {
    pills {
      id
      name
      dosage
      prescriptionDate
    }
  }
`;

// Fetch using GraphQL
async function getPills() {
    const response = await fetch($BASE_URL + '/graphql', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ query: GET_PILLS }),
        credentials: 'include'
    });
    
    const result = await response.json();
    pills = result.data.pills;
}
```

These advanced patterns could enhance the application as it grows in complexity.

---

[<- Back to Main Note](./README.md) | [Previous: Server-Side Rendering](./05-server-side-rendering.md)
