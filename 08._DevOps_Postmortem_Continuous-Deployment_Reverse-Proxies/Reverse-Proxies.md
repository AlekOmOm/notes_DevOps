# Nginx Reverse-Proxy


flow: 

```
       -1.->       -2.-> 
Client       Nginx      Server
       <-4.-       <-3.- 
```

## Usages of Reverse-Proxy

- Load Balancing
- HTTP Caching
- Security
    - Port protection in a centralized manner
    - IP Whitelisting

### terms

#### 1. Load Balancing

def: 
- Distributing client requests across multiple servers.

explanation: 
- Nginx can distribute client requests across multiple servers.
- distribution: 
    - strategies: 
        - Round Robin
        - Least Connections
        - IP Hash
        - Random
        - Weighted Load Balancing







