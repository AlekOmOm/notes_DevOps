# 1. Client-Server Overview 🌐

[<- Back to Main Note](./README.md) | [Next: Svelte Frontend ->](./02-svelte-frontend.md)

## Table of Contents

- [Client-Server Architecture](#client-server-architecture)
- [Project Structure](#project-structure)
- [Communication Flow](#communication-flow)
- [Development Environment](#development-environment)
- [Deployment Considerations](#deployment-considerations)

## Client-Server Architecture

The Medicine project demonstrates a classic client-server architecture where responsibilities are clearly separated:

### Client Responsibilities

- User interface rendering
- State management
- Client-side routing
- Form handling and validation
- API communication

The client is built with Svelte, a modern JavaScript framework that compiles components at build time rather than interpreting them at runtime, resulting in highly optimized code.

### Server Responsibilities

- API endpoints provision
- Data processing
- Session management
- Business logic execution
- Database interactions (future implementation)

The server has two variations:
1. **Regular Express server**: Provides API endpoints for client consumption
2. **SSR server**: Renders Svelte components on the server for improved initial load performance

## Project Structure

```
medicine/
├── client/                 # Svelte frontend
│   ├── src/
│   │   ├── components/     # Reusable UI components
│   │   ├── pages/          # Page components
│   │   ├── stores/         # Svelte stores
│   │   ├── util/           # Utility functions
│   │   ├── App.svelte      # Root component
│   │   └── main.js         # Entry point
│   ├── index.html          # HTML template
│   └── package.json        # Frontend dependencies
├── server/                 # Regular Express.js backend
│   ├── routers/            # Route handlers
│   ├── app.js              # Server configuration
│   └── package.json        # Backend dependencies
└── serverSSR/              # Server-side rendering backend
    ├── routers/            # Route handlers
    ├── app.js              # SSR server configuration
    └── package.json        # SSR dependencies
```

This separation provides clear boundaries of responsibility and allows for independent development and scaling of each tier.

## Communication Flow

1. **Client Request Flow**:
   - User interacts with Svelte UI
   - Component events trigger API calls via fetch
   - Server processes requests and returns responses
   - UI updates based on response data

2. **Server Processing Flow**:
   - Express router handles incoming requests
   - Middleware processes request (CORS, JSON parsing, session)
   - Route handler executes business logic
   - Response is formatted and returned to client

## Development Environment

The project uses modern JavaScript tooling:

- **Vite**: Fast build tool for frontend development
- **Node.js**: JavaScript runtime for server execution
- **npm**: Package management for dependencies
- **Environment Variables**: .env files for configuration

Development workflow:
1. Run client in development mode with hot module replacement
2. Run server in parallel, watching for changes
3. API communication between the locally running services

## Deployment Considerations

The architecture is designed to support multiple deployment scenarios:

1. **Traditional Deployment**:
   - Static client files served from CDN
   - Server running on application server

2. **Server-Side Rendering Deployment**:
   - Single server handling both rendering and API requests
   - Improved SEO and initial load performance

3. **Containerized Deployment**:
   - Each component running in separate containers
   - Orchestration for scaling and resilience

The flexibility of this architecture enables adapting to different deployment requirements as the application evolves.

---

[<- Back to Main Note](./README.md) | [Next: Svelte Frontend ->](./02-svelte-frontend.md)
