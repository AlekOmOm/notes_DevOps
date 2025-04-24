# 2. Svelte Frontend 🔄

[<- Back to Main Note](./README.md) | [Previous: Client-Server Overview](./01-client-server-overview.md) | [Next: Express.js Backend ->](./03-express-backend.md)

## Table of Contents

- [Svelte Core Concepts](#svelte-core-concepts)
- [Component Structure](#component-structure)
- [Routing Implementation](#routing-implementation)
- [State Management](#state-management)
- [API Communication](#api-communication)

## Svelte Core Concepts

Svelte is a modern JavaScript framework that takes a fundamentally different approach compared to frameworks like React or Vue:

- **Compile-time framework**: Svelte shifts much of its work to the build step rather than the browser
- **No virtual DOM**: Updates DOM directly without the overhead of diffing algorithms
- **Reactive declarations**: Simple and intuitive reactive programming model
- **Less boilerplate**: Minimal code required for powerful functionality

In the Medicine project, Svelte 5 is used with its new features:

```javascript
// Using $state in Svelte 5 (from Employees.svelte)
let employees = $state([]);

onMount(() => {
    fetch($BASE_URL+"/employees")
    .then((response) => response.json())
    .then((result) => {
        employees = result.data;
    });
});
```

## Component Structure

The Medicine project follows a well-organized component structure:

### Pages Components

Located in `src/pages/`, these represent full views or routes:

```
pages/
├── Home/
│   └── Home.svelte      # Home page component
├── Pharmacy/
│   └── Pharmacy.svelte  # Pharmacy page component
└── About/
    └── About.svelte     # About page component
```

Each page component encapsulates a specific view and may import reusable components.

### Reusable Components

Located in `src/components/`, these are modular, reusable parts:

```
components/
└── Employees/
    └── Employees.svelte # Reusable employee list component
```

Example of component composition from `Home.svelte`:

```svelte
<script>
    import Employees from "../../components/Employees/Employees.svelte";
</script>

<h1>Home</h1>

<Employees />
```

### Root Component

`App.svelte` serves as the application shell, setting up routing and global layout:

```svelte
<script>
  import { Router, Link, Route } from "svelte-routing";
  import Home from "./pages/Home/Home.svelte";
  import Pharmacy from "./pages/Pharmacy/Pharmacy.svelte";
  import About from "./pages/About/About.svelte";

  export let url = "";
</script>

<Router {url}>
  <nav>
    <Link to="/">Home</Link>
    <Link to="/pharmacy">Pharmacy</Link>
    <Link to="/about">About</Link>
  </nav>

  <div>
    <Route path="/" >
        <Home />
    </Route>
    <Route path="/about"><About /></Route>
    <Route path="/pharmacy"><Pharmacy></Pharmacy></Route>
  </div>
</Router>
```

## Routing Implementation

The project uses `svelte-routing` for client-side routing:

1. **Router**: Wraps the entire application to provide routing context
2. **Link**: Creates navigation links that update the URL without page reloads
3. **Route**: Defines component to render for specific URL paths

This pattern allows for a single-page application experience with distinct URL routes.

Routing example from `App.svelte`:

```svelte
<Router {url}>
  <nav>
    <Link to="/">Home</Link>
    <Link to="/pharmacy">Pharmacy</Link>
    <Link to="/about">About</Link>
  </nav>

  <div>
    <Route path="/" >
        <Home />
    </Route>
    <Route path="/about"><About /></Route>
    <Route path="/pharmacy"><Pharmacy></Pharmacy></Route>
  </div>
</Router>
```

## State Management

The Medicine project utilizes Svelte's built-in state management capabilities:

### Local Component State

Component-specific state using Svelte's reactive variables:

```javascript
// In Employees.svelte
let employees = $state([]);
```

### Global Stores

Application-wide state using Svelte stores:

```javascript
// In generalStore.js
import { readable } from "svelte/store";

export const BASE_URL = readable(import.meta.env.VITE_BASE_URL || "http://localhost:8080");
```

Using store values in components:

```javascript
// In Pharmacy.svelte
import { BASE_URL } from "../../stores/generalStore.js";

// Accessing the store value with $ prefix
let url = $BASE_URL + "/pills";
```

This provides a clean way to share state across components without prop drilling.

## API Communication

The Medicine project implements a clean approach to API communication:

### Utility Functions

In `src/util/fetch.js`, abstracted fetch functions standardize API calls:

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

### Usage in Components

API calls are made during component lifecycle events:

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

This approach ensures consistent handling of API requests and responses throughout the application.

---

[<- Back to Main Note](./README.md) | [Previous: Client-Server Overview](./01-client-server-overview.md) | [Next: Express.js Backend ->](./03-express-backend.md)
