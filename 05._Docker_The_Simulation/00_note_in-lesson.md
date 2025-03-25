

content:
- 01 intro
- 02 Build tools 
- 03 Packaging 
- 04 virtualization
- 05 Docker 
- 06 Dockerfile 


# Docker 

conceptually Docker is used for packaging

interestingly:

- Docker is comparable to NPM, Maven etc.

## Docker Hub and GitHub Packages

- Docker Hub is like GitHub
    - Docker Hub is a registry for Docker images

- GitHub Packages is like Docker Hub
    - GitHub Packages is a registry for Docker images

### utilizing the registries

- Docker Hub
    - `docker pull <image-name>`
    - `docker push <image-name>`

- GitHub Packages
    - `docker pull ghcr.io/<username>/<image-name>`
    - `docker push ghcr.io/<username>/<image-name>`

note: 

so GitHub Packages can be utilized with Docker 


## Virtualization 

***Virtualization*** 
can: 
- Hardware 
- OS

is: 
- running multiple OS on a single machine
    - each OS is running in a separate VM
        - each VM has its own kernel
    - each VM has its own OS

- Docker is not a virtualization tool
    - Docker is a containerization tool

- Docker containers are not VMs
    - since Docker containers share the host OS kernel


### hardware vs software resources for VMs 

***VMs***
- hardware resources: 
    - *shared among the VMs*
    - CPU, RAM, Disk 
- software resources: 
    - *not shared among the VMs*
    - OS, Kernel etc. 




## Hypervisor 

- Hypervisor is a software that runs VMs
    - Hypervisor is a software that runs multiple OS on a single machine
    - Hypervisor is a software that runs multiple VMs on a single machine


## Docker Containerization 

benefits:
- VMs require a new OS for each environment 

- Docker containers share the host OS kernel


### characteristics of Images 

attributes:
- lightweight, standalone, executable package of software

- containers are: 
    - isolated environments

workflow difference:

- Docker images allow in DevOps to:
    - build, ship, and run applications in containers  

    - environment consistency
        - same environment in development, testing, and production

    - Docker images are immutable
        - once created, they cannot be changed

        - to update an image, a new image must be created

    - Docker images are versioned
        - to track changes to the image


## history of Docker 

- Docker was created in 2013
    - by Solomon Hykes

### made possible by Namespacing and Cgroups (control groups)

***namespacing***
- isolates processes, network, and filesystem
    - hard drive. networking, hostnames, users, etc.

***cgroups***
- limits and isolates resource usage
    - CPU, memory, disk I/O, network, etc.


### history of containers

chroot 1979-1982

FreeBSD jail 1999

Linux VServer 2001, OpenVZ 2005, LXC 2008
2001-2008

Docker 2013

*modern:*

- containerd
- Podman 
- Kata Containers 
- Kubernetes
- Docker 











































# note: 

DevOps ideal 

is that everyone is devops developers

thus discussion of
- DevOps developer and normal developers 
or 
- everyone DevOps developers
    - everyone is responsible for the whole lifecycle of the software

but now 

- if firm has DevOps team
    - then it is not 'DevOps' but Operations 





