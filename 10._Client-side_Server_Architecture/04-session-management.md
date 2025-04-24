# 4. Session Management 🔑

[<- Back to Main Note](./README.md) | [Previous: Express.js Backend](./03-express-backend.md) | [Next: Server-Side Rendering ->](./05-server-side-rendering.md)

## Table of Contents

- [Sessions in Web Applications](#sessions-in-web-applications)
- [Implementation with express-session](#implementation-with-express-session)
- [Server-Side Session Storage](#server-side-session-storage)
- [Session Security Considerations](#session-security-considerations)
- [Client-Side Interaction](#client-side-interaction)

## Sessions in Web Applications

HTTP is stateless by design, meaning each request is independent with no inherent way to associate multiple requests from the same client. Sessions solve this problem by creating a persistent state between client and server.

### Why Sessions?

1. **Maintaining state**: Keep track of user authentication, preferences, or activity
2. **User experience**: Provide personalized content without requiring re-authentication
3. **Data persistence**: Store temporary data across multiple requests
4. **Security**: Avoid sending sensitive data in every request

### Session vs. Local Storage

| Feature | Sessions | Local Storage |
|---------|----------|---------------|
| Storage Location | Server-side (secure) | Client-side (browser) |
| Lifetime | Configurable (can expire) | Persistent until cleared |
| Size Limit | Larger (server capacity) | ~5MB per domain |
| Automatic Transmission | Yes (via cookies) | No (requires code) |
| Security | More secure (not accessible to client JS) | Less secure (accessible to any JS) |

## Implementation with express-session

The Medicine project uses the `express-session` middleware for session management:

### Installation

```bash
npm install express-session
```

### Basic Configuration

```javascript
import session from 'express-session';

app.use(session({
    secret: process.env.SESSION_SECRET,
    resave: false,
    saveUninitialized: true,
    cookie: { secure: false }
}));
```

### Configuration Options Explained

- **secret**: Used to sign the session ID cookie (should be a strong, unique value)
- **resave**: Forces session to be saved back to the store, even if not modified
- **saveUninitialized**: Forces an "uninitialized" session to be saved to the store
- **cookie**: Settings for the session cookie
  - **secure**: When true, cookie only sent over HTTPS
  - **maxAge**: Lifetime of cookie in milliseconds (default: session ends when browser closes)
  - **httpOnly**: Prevents client-side JavaScript from accessing cookies

## Server-Side Session Storage

In the Medicine project, session data is used to store pills that have been added:

```javascript
// pillsRouter.js
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
```

### Default Memory Store

By default, `express-session` uses a memory store (MemoryStore) which is:
- Not designed for production use
- Not scaled across multiple processes or servers
- Subject to memory leaks over time
- Loses all sessions on server restart

### Production Store Options

For production applications, alternative session stores should be used:

```javascript
// Example with connect-redis (not in current project)
import session from 'express-session';
import RedisStore from 'connect-redis';
import { createClient } from 'redis';

// Redis client
const redisClient = createClient({ 
    url: process.env.REDIS_URL 
});
await redisClient.connect();

// Redis store
const redisStore = new RedisStore({
  client: redisClient,
  prefix: "myapp:",
});

// Session configuration
app.use(session({
    store: redisStore,
    secret: process.env.SESSION_SECRET,
    resave: false,
    saveUninitialized: true,
    cookie: { secure: false }
}));
```

Common production session stores:
- **Redis**: Fast, in-memory data store, good for distributed systems
- **MongoDB**: Document database, good when already using MongoDB
- **PostgreSQL/MySQL**: Relational databases, good for existing SQL infrastructure
- **DynamoDB**: AWS-native solution, good for AWS deployments

## Session Security Considerations

Session management involves several security considerations:

### Session Hijacking Prevention

1. **Use HTTPS**: All session cookies should be transmitted only over secure connections
   ```javascript
   app.use(session({
       cookie: { secure: true } // Only works over HTTPS
   }));
   ```

2. **HttpOnly flag**: Prevents client-side JavaScript from accessing cookies
   ```javascript
   app.use(session({
       cookie: { httpOnly: true }
   }));
   ```

3. **SameSite attribute**: Prevents cross-site request forgery
   ```javascript
   app.use(session({
       cookie: { sameSite: 'strict' }
   }));
   ```

### Session Fixation Protection

Express-session helps prevent session fixation by generating a new session ID when a user authenticates:

```javascript
// When user logs in:
req.session.regenerate((err) => {
    if (err) next(err);
    
    // Store user info in session AFTER regeneration
    req.session.userId = user.id;
    req.session.save((err) => {
        if (err) next(err);
        res.redirect('/dashboard');
    });
});
```

### Session Expiration

Set appropriate timeout values to limit the window of opportunity for attacks:

```javascript
app.use(session({
    cookie: { 
        maxAge: 60000 * 60 * 24, // 24 hours in milliseconds
    }
}));
```

## Client-Side Interaction

In the Medicine project, the client interacts with session-based data:

### Sending Credentials with Fetch

The fetch utility is configured to include credentials (cookies):

```javascript
// fetch.js
export async function fetchGet(url) {
    try {
        const response = await fetch(url, {
            credentials: "include"  // Include cookies in requests
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
        credentials: "include",  // Include cookies in requests
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

### CORS Configuration for Credentials

When sessions use cookies, special CORS settings are required:

```javascript
// Server-side CORS settings
app.use((req, res, next) => {
    res.header("Access-Control-Allow-Origin", req.headers.origin || "*");
    res.header("Access-Control-Allow-Credentials", "true");  // Essential for cookies
    res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
    next();
});
```

### Session-Based UI Updates

Components update their state based on session data from the server:

```javascript
// In Pharmacy.svelte
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

This pattern ensures client state stays in sync with server session state.

---

[<- Back to Main Note](./README.md) | [Previous: Express.js Backend](./03-express-backend.md) | [Next: Server-Side Rendering ->](./05-server-side-rendering.md)
