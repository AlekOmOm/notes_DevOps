# DevSecOps

topics:

DevSecOps

Docker / Firewalls

Security in GitHub

Continuous Testing

## DevSecOps



### SAST vs DAST

SAST: Static Application Security Testing
DAST: Dynamic Application Security Testing

#### in DevSecOps cycle

SAST before Build 

DAST in Test 

##### implementation in Rust Actix Web 

SAST: cargo-audit
- def: checks for vulnerabilities in dependencies
- use: in CI/CD pipeline
    - in CI pipeline, run `cargo audit` before build

DAST: OWASP ZAP
- def: checks for vulnerabilities in running Application
- use: in CI/CD pipeline
    - in Test pipeline, run OWASP ZAP against the running application

Python tools

- safety: SAST
- Bandit: SAST
- OWASP ZAP: DAST

Rust tools 

- cargo-audit: SAST
- OWASP ZAP: DAST


###### audit.yml 

```yaml
name: audit
on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main

jobs:
    audit:
        runs-on: ubuntu-latest
        steps:
        - uses: actions/checkout@v2
        - name: Install dependencies
            run: cargo install cargo-audit
        - name: Run audit
            run: cargo audit
```




### Monitor

following aspects:
- traffix
- access 
- file changes 
    - fx. limited files should be present on server, especially if docker-compose pull and running docker containers

tool: 
- Dashboard tool: Zabbix

###  prep for Breach 

- plan for data backups
  - volumes data from docker containers


## Docker / Firewalls



### def Firewall

Firewalls:

def: 
- network security device that monitors and controls incoming and outgoing network traffic based on predetermined security rules

- hardware or software level 

types:

- Packet-filtering Firewalls
- Stateful Firewalls
- Proxy Firewalls
- Next-generation Firewalls (NGFW)


### Firewalls in Linux

#### UFW and iptables 


#### Docker Firewall and Porting

##### possible Docker issue: 

Docker circumvents the UFW firewall and alters iptables directly when you instruct it about ports

Mapping the ports with -p 9200:9200 (or in docker-compose) maps the port to the host but also opens it to the world! (bug report from '19)

##### solution:

Define the IP range to control where the service is accessible.

Internal service (only accessible from the host):

```yaml
ports:
  - "127.0.0.1:8080:8080"
```

Public service (accessible externally):

```yaml
ports:
  - "80:80"
```




