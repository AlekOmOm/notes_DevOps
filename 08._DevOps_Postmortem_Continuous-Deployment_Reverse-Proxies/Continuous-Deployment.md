# Continuous Deployment


## Full CD 

1. scp docker-compose.yml onto server 
2. docker-compose pull
3. docker-compose up -d

### important observations

#### workflow file
- builds
    - image 
    - pushes to image registry (docker hub or github container registry)
- deploy
    - scp docker-compose.yml to server
    - docker-compose pull
    - docker-compose up -d




Docker Hub 

image: ghcr.io/username/repo:tag

***benefit of scp vs git pull*** 
- git: git pull 
- scp: simple transfer of docker-compose.yml file


### 


## Reduced Runtime - Quality Gates 


### Quality Gates

def: 
- securing quality and redcing runtime by running tests before deployment

```yaml

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - name: Build the Docker image
      run: docker build . -t my-image:latest

      if: success() 

```


#### multiple jobs for parallel processing and quality gate 'depends-on'

```yaml

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - name: Build the Docker image
      run: docker build . -t my-image:latest

  test:
    runs-on: ubuntu-latest
    needs: build
    steps:
    - uses: actions/checkout@v2
    - name: Run tests
      run: docker run my-image:latest test

  deploy:
    runs-on: ubuntu-latest

    needs: test

    steps:
    - uses: actions/checkout@v2
    - name: Deploy
      run: docker run my-image:latest deploy

```
- note: '***needs***' keyword is used to specify the job that the current job depends on.

### Rollback




## how big companies Build and Deploy

yt ref: DoorDash principal engineer - MicroServices are Technical Debt




































