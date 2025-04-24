# 5. Server-Side Rendering 🖥️

[<- Back to Main Note](./README.md) | [Previous: Session Management](./04-session-management.md) | [Next: Client-Server Communication ->](./06-client-server-communication.md)

## Table of Contents

- [SSR Fundamentals](#ssr-fundamentals)
- [SSR vs. Client-Side Rendering](#ssr-vs-client-side-rendering)
- [Implementation in Express.js](#implementation-in-expressjs)
- [Static File Serving](#static-file-serving)
- [SPA Fallback Route](#spa-fallback-route)

## SSR Fundamentals

Server-Side Rendering (SSR) is a technique where web pages are generated on the server rather than in the browser. This approach contrasts with Client-Side Rendering (CSR), where JavaScript builds the page in the browser.

### Core Concepts

1. **Pre-rendering**: Server generates HTML before sending to client
2. **Hydration**: Client-side JavaScript takes over once page loads
3. **Isomorphic code**: Same codebase runs on both server and client
4. **Universal rendering**: Initial server render followed by client interactions

### Advantages of SSR

- **Improved SEO**: Search engines index fully-rendered content
- **Faster initial load**: First contentful paint happens sooner
- **Better performance on low-powered devices**: Less client-side processing
- **Improved accessibility**: Content available without JavaScript

## SSR vs. Client-Side Rendering

The Medicine project includes both approaches, allowing for comparison:

| Aspect | Server-Side Rendering | Client-Side Rendering |
|--------|----------------------|----------------------|
| **Initial Load** | Faster (pre-rendered HTML) | Slower (requires JS execution) |
| **Subsequent Loads** | Slower (full page refresh) | Faster (only data updates) |
| **SEO** | Better (complete HTML for crawlers) | Poorer (requires JS execution) |
| **Server Load** | Higher (rendering on server) | Lower (rendering on client) |
| **Implementation** | More complex | Simpler |
| **Code Structure** | `serverSSR/app.js` | `server/app.js` + `client/` |

## Implementation in Express.js

The Medicine project includes a server variant specifically for SSR in the `serverSSR` directory:

```javascript
// serverSSR/app.js
import 'dotenv/config';
import express from 'express';
import path from 'path';

const app = express();

app.use(express.json());

// Serve static files from client build directory
app.use(express.static(path.resolve('../client/dist/')));

// Session middleware
import session from 'express-session';
app.use(session({
    secret: process.env.SESSION_SECRET,
    resave: false,
    saveUninitialized: true,
    cookie: { secure: false }
}));

// API Routes
import employeesRouter from './routers/employeesRouter.js';
app.use(employeesRouter);
import pillsRouter from './routers/pillsRouter.js';
app.use(pillsRouter);

// SPA fallback route
app.get("/{*splat}", (req, res) => {
  res.sendFile(path.resolve('../client/dist/index.html'));
});

// Start server
const PORT = Number(process.env.PORT) || 8080;
app.listen(PORT, () => console.log("Server is running on port", PORT));
```

The key differences from the standard server are:
1. Static file serving middleware
2. SPA fallback route for client-side routing support

## Static File Serving

Express.js provides built-in middleware for serving static files:

```javascript
app.use(express.static(path.resolve('../client/dist/')));
```

This configuration:
- Serves all files from the client's build directory (`dist`)
- Handles basic caching headers automatically
- Supports all file types (HTML, CSS, JS, images, etc.)

For a production setup, additional considerations might include:

```javascript
// Production-ready static file serving (not in current project)
app.use(express.static(path.resolve('../client/dist/'), {
    maxAge: '1d',             // Cache for one day
    etag: true,               // Use ETags for caching
    lastModified: true,       // Use Last-Modified for caching
    immutable: true,          // Assets with hashed filenames never change
    index: false              // Disable automatic index.html serving
}));
```

## SPA Fallback Route

A critical component for Single Page Applications is the fallback route that handles client-side routing:

```javascript
app.get("/{*splat}", (req, res) => {
  res.sendFile(path.resolve('../client/dist/index.html'));
});
```

This pattern:
1. Captures all unhandled routes with a wildcard pattern
2. Returns the main `index.html` file instead of a 404 error
3. Allows the client-side router to handle the URL path
4. Must be defined after all API routes to avoid conflicts

### Client-Side Routing with SSR

With server-side rendering, client-side routing requires special handling:

1. The server returns `index.html` for any unmatched route
2. The client-side router (svelte-routing) initializes with the current URL
3. The router renders the appropriate component based on the URL path

```svelte
<!-- App.svelte -->
<script>
  import { Router, Link, Route } from "svelte-routing";
  import Home from "./pages/Home/Home.svelte";
  import Pharmacy from "./pages/Pharmacy/Pharmacy.svelte";
  import About from "./pages/About/About.svelte";

  export let url = "";  // SSR provides the initial URL
</script>

<Router {url}>
  <!-- Navigation and routes -->
</Router>
```

## Build Pipeline for SSR

For Svelte with SSR, the build pipeline typically includes:

1. **Client Build**: Generate optimized assets
   ```bash
   # Build client assets
   cd client
   npm run build
   ```

2. **Server Startup**: Use those pre-built assets
   ```bash
   # Start SSR server
   cd serverSSR
   node app.js
   ```

In the Medicine project, the client includes a special build-watch script for development:

```json
// client/package.json
{
  "scripts": {
    "build": "vite build",
    "build-watch": "vite build --watch"
  }
}
```

This watches for changes and rebuilds the client automatically, which is then immediately picked up by the SSR server.

## Performance Considerations

Server-side rendering introduces specific performance considerations:

### Server-Side Optimizations

1. **Response Caching**: Cache rendered HTML for static or rarely changing pages
   ```javascript
   // Example with simple in-memory cache (not in current project)
   const pageCache = {};
   
   app.get('/', (req, res) => {
     const cacheKey = req.originalUrl;
     
     if (pageCache[cacheKey] && !isDevelopment) {
       return res.send(pageCache[cacheKey]);
     }
     
     const html = renderPage();  // Expensive rendering
     pageCache[cacheKey] = html;
     res.send(html);
   });
   ```

2. **Selective Hydration**: Only hydrate interactive parts of the page
   ```javascript
   // In a more complex SSR setup (not in current project)
   hydrate(staticParts, { hydrate: false });
   hydrate(interactiveParts, { hydrate: true });
   ```

### Client-Side Optimizations

1. **Code Splitting**: Load only necessary JavaScript
   ```javascript
   // Vite handles this automatically with dynamic imports
   import('./features/heavyFeature.js').then(module => {
     // Use the module only when needed
   });
   ```

2. **Progressive Enhancement**: Ensure basic functionality without JavaScript
   ```html
   <!-- Form works without JS but enhanced with JS -->
   <form action="/api/pills" method="post" data-enhance-with-js>
     <!-- Form fields -->
   </form>
   ```

## Deploying SSR Applications

SSR applications have specific deployment requirements:

1. **Node.js environment**: The server must run in a Node.js environment
2. **Process management**: Use tools like PM2 or Docker for process management
3. **Reverse proxy**: Place Nginx or similar in front of Node.js for performance
4. **Scaling considerations**: SSR is more CPU-intensive than static file serving

Example deployment architecture:

```
User → CDN (static assets) → Nginx (reverse proxy) → Node.js SSR Server → Database
```

This approach combines the performance benefits of static asset caching with the dynamic capabilities of server-side rendering.

---

[<- Back to Main Note](./README.md) | [Previous: Session Management](./04-session-management.md) | [Next: Client-Server Communication ->](./06-client-server-communication.md)
