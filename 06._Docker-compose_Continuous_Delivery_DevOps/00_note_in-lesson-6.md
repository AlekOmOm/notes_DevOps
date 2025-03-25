

content
1. docker-compose
2. hot reload in docker 
3. debug docker-compose
4. agile
5. DevOps
6. Continuous Delivery

## terms
 (structure: def, explanation, example)

- docker-compose
 

## 1. docker-compose

- def:
    - docker-compose is a tool for defining and running multi-container Docker applications. With Compose, you use a YAML file to configure your application’s services. Then, with a single command, you create and start all the services from your configuration.

- explanation:
    - Compose is great for development, testing, and staging environments, as well as CI workflows. You can define a multi-container application in a single file, then spin your application up in a single command which does everything that needs to be done to get it running.

- example:

```yaml


### docker compose vs docker-compose

traditional: docker-compose

new Docker CLI: docker compose 

syntax difference:

```bash

docker-compose build web 
#-> node_project_web

docker compose build web 
#-> node_project-web

```

### docker / awesome-compose library


example: /spring-postgres

```yaml
services:
  backend:
    build: backend
    ports:
      - 8080:8080
    environment:
      - POSTGRES_DB=example
    networks:
      - spring-postgres
  db:
    image: postgres
    restart: always
    secrets:
      - db-password
    volumes:
      - db-data:/var/lib/postgresql/data
    networks:
      - spring-postgres
    environment:
      - POSTGRES_DB=example
      - POSTGRES_PASSWORD_FILE=/run/secrets/db-password
    expose:
      - 5432
volumes:
  db-data:
secrets:
  db-password:
    file: db/password.txt
networks:
  spring-postgres:
```

note on /spring-postgres:
- defining 
    - two services: backend and db,
    - a volume: db-data,
    - a secret: db-password
        - db-password in file at: password.txt
    - a network: spring-postgres

- services 
    - backend 
        - environment: POSTGRES_DB=example 
            - sets env var POSTGRES_DB (which is db name)
            - env var is then available to backend service 


### Networking in Docker Compose

```yaml

services:
  web:
    build: .
    ports:
      - "5000:5000"
  db:
    image: "postgres:alpine"
    ports:
      - "5432:5432"

### volumes vs bind mounts

diff: management

- volumes = fully managed by Docker

- bind mounts = managed by user and thus dependent on OS


#### restart policies

- no: never restart
- always: always restart
- on-failure: restart only if container exits with non-zero status
- unless-stopped: always restart unless user stops it

##### with Volumes

restarting policies are usually used with volumes

- if container is stopped, 
    - it will be restarted with the same volume

- if container is removed, 
    - the volume will be removed as well

#### nginx and volumes

def: 
- nginx is a web server that can also be used as a reverse proxy, load balancer, mail proxy, and HTTP cache

Dockerfile utilize nginx with volumes

- nginx docker image
- nginx.conf file

```Dockerfile

FROM nginx:latest
COPY nginx.conf /etc/nginx/nginx.conf

```
```nginx.config

events { worker_connections 1024; }

http {
    server {
        listen 80;

        location / {
            root /usr/share/nginx/html;
            index index.html index.htm;
        }
    }
}

```

### Makefile for easing Docker cmds

```makefile
.PHONY: postgresql access_postgresql all 

postgresql:
    @echo "Starting PostgreSQL..."
    cd postgresql && docker-compose up -d

access_postgresql:
    @echo "Accessing PostgreSQL..."
    docker exec -it postgresql_db_1 psql -U postgres

all: postgresql access_postgresql
```

#### utilizing Makefiles instead of .sh scripts

- Makefiles are more readable
- Makefiles are more maintainable
- Makefiles allow 


## 2. hot reload in docker

table Language Tool:

| Language | Tool |
|----------|------|
| Python   | Comes built-in with many frameworks |
| Java    | jrebel / Spring Boot DevTools |
| Node.js  | nodemon |
| Rust    | cargo-watch |
| Ruby   | guard / rerun |
| Go      | air / realize |


problem:
- Docker makes it harder to achieve hot-reload
Goal:
- Improve development experience by enabling automatically reloading application when the code changes





## 3. debug docker-compose

### prod/dev environemnt

docker-compose can set environment variables for different environments 

fx.
- docker-compose.prod.yml
- docker-compose.dev.yml

```yaml

    environment:
      - FLASK_ENV=development
```

then in python flask app

```Python

    app.config['FLASK_ENV']

    app.run(host="0.0.0.0", port=8080, debug=DEBUG)

```


### debugging in docker-compose

- docker-compose exec <service> <command>

- docker-compose ps 
    - lists all services in docker-compose (in current directory)

- docker-compose logs 
    - shows logs of all services

- docker-compose logs <service>
    - shows logs of a service

- docker ps --format "{{.Names}}: {{.Ports}}"


- docker exec -it <container_name> ss -tuln

```

    05._test> docker exec -it 05_test-app-1 ss -tuln
    Netid    State     Recv-Q    Send-Q       Local Address:Port          Peer Address:Port
    udp      UNCONN    0         0               127.0.0.11:37492              0.0.0.0:*
    tcp      LISTEN    0         4096            127.0.0.11:46425              0.0.0.0:*
    tcp      LISTEN    0         511                      *:80                       *:*

    What's next:
        Try Docker Debug for seamless, persistent debugging tools in any container or image → docker debug 05_test-app-1
        Learn more at https://docs.docker.com/go/debug-cli/
```



## 4. agile

- def: 
    - Agile is a project management methodology that uses short development cycles called "sprints" to focus on continuous improvement in the development of a product or service.

- explanation:
    - Agile is a time-boxed, iterative approach to software delivery that builds software incrementally from the start of the project, instead of trying to deliver it all at once near the end.

- example:
    - Scrum, Kanban, Lean, Extreme Programming (XP), Crystal, Dynamic Systems Development Method (DSDM), Feature-Driven Development (FDD), Adaptive Software Development (ASD), and Crystal.

### Historical view 

before agile

- waterfall model

phases:
1. requirement gathering and analysis
2. system design
3. implementation
4. testing
5. deployment
6. maintenance

[waterfall image](./assets/waterfall_model.png)


*benefits of waterfall*

- clear requirements

- project type: small, simple, and well-understood
- team: experienced and skilled

### Agile Manifesto 

...



### problems with pure agile 

- Culture clash
- Lack of leadership support
- Siloed teams







## 5. DevOps


















