# 7. System Resilience 🔐

[<- Back: Kubernetes Hands-On](./06-kubernetes-hands-on.md) | [Next: Maintenance Best Practices ->](./08-maintenance.md)

## Table of Contents

- [Introduction](#introduction)
- [Chaos Engineering](#chaos-engineering)
- [Tools and Implementations](#tools-and-implementations)
- [Game Days](#game-days)
- [Real-World Examples](#real-world-examples)
- [Health Checks and Monitoring](#health-checks-and-monitoring)
- [Creating a Resilience Testing Strategy](#creating-a-resilience-testing-strategy)
- [Summary](#summary)

## Introduction

System resilience refers to a system's ability to maintain acceptable performance in the face of faults and challenges. Traditional testing methods often focus on validating that systems work under ideal conditions, but they frequently miss how systems behave under stress, partial failure, or unexpected circumstances.

This section explores how to build and verify system robustness against failures, focusing on proactive approaches that deliberately introduce controlled failures to identify weaknesses before they cause real problems.

## Chaos Engineering

Chaos Engineering is the discipline of experimenting on a system to build confidence in its capability to withstand turbulent conditions in production.

### Core Principles

1. **Build a Hypothesis**: Start with a hypothesis about how the system should behave under stress
2. **Introduce Real-World Events**: Simulate events like server failures, network issues, or traffic spikes
3. **Run Experiments in Production**: Test in real environments for authentic results
4. **Minimize Blast Radius**: Contain potential damage by limiting the scope of experiments
5. **Automate Experiments**: Run chaos experiments continuously as part of your testing pipeline

### Methodology

A structured approach to Chaos Engineering involves:

1. **Define steady state**: Establish metrics that indicate normal operation
2. **Hypothesize that state will continue**: Assume these metrics will remain stable during disruption
3. **Introduce variables**: Simulate real-world events (server failures, network latency, etc.)
4. **Observe results**: Look for deviations from the steady state
5. **Improve the system**: Fix weaknesses uncovered by the experiments

```javascript
// Example hypothesis in pseudo-code
hypothesis = {
  title: "Application remains responsive when database latency increases",
  steadyStateMetrics: [
    { name: "http_response_time_95th", threshold: 500 },
    { name: "error_rate", threshold: 0.1 }
  ],
  experiment: {
    action: "increase_database_latency",
    parameters: { latency: "100ms", duration: "15m" }
  },
  rollbackPlan: {
    trigger: { name: "error_rate", threshold: 5.0 },
    action: "restore_normal_latency"
  }
};
```

## Tools and Implementations

Several tools have emerged to facilitate Chaos Engineering practices:

### Netflix Simian Army

Netflix pioneered Chaos Engineering with their "Simian Army" suite of tools:

- **Chaos Monkey**: Randomly terminates instances in production
- **Latency Monkey**: Introduces artificial delays in network communication
- **Conformity Monkey**: Finds instances that don't adhere to best practices
- **Janitor Monkey**: Identifies and cleans up unused resources
- **Security Monkey**: Finds security violations or vulnerabilities

The Chaos Monkey tool is available as open source: [GitHub - Netflix/chaosmonkey](https://github.com/Netflix/chaosmonkey)

https://netflixtechblog.com/the-netflix-simian-army-16e57fbab116

https://netflix.github.io/chaosmonkey/

<img src="./assets_resilience/chaosmonkey_logo.png" alt="chaosmonkey logo">


### KubeInvaders

KubeInvaders is a gamified chaos engineering tool for Kubernetes:

- Visualizes Kubernetes pods as space invaders
- Allows operators to "shoot down" pods to test resilience
- Provides a fun, interactive way to introduce chaos
- Available at: [KubeInvaders](https://kubeinvaders.platformengineering.it/)

### DIY Chaos Tools

You can create simple chaos tools to test specific aspects of your system. Here's an example of a basic "chaos monkey" script for Kubernetes:

```bash
#!/bin/bash
# keasmonkey.sh - A simple chaos script for Kubernetes

while true
do
    echo "Choosing a pod to kill..."

    PODS=$(kubectl get pods | grep -v NAME | awk '{print $1}')
    POD_COUNT=$(kubectl get pods | grep -v NAME | wc -l)

    if [ "$POD_COUNT" -eq 0 ]; then
        echo "No pods found. Exiting loop."
        break
    fi

    K=$(( (RANDOM % POD_COUNT) + 1))

    TARGET_POD=$(kubectl get pods | grep -v NAME | awk '{print $1}' | head -n ${K} | tail -n 1)

    echo "Killing pod $TARGET_POD"
    kubectl delete pod $TARGET_POD

    sleep 1
done
```

## Game Days

Game Days are scheduled events where teams simulate failures or incidents to test systems and team responses.

### Key Components

1. **Planning**:
   - Define clear objectives
   - Establish a "blast radius" (scope of potential impact)
   - Create detailed scenarios
   - Assign roles (facilitator, observers, responders)

2. **Execution**:
   - Introduce the planned failure
   - Teams respond as they would to a real incident
   - Document observations and response times
   - Implement circuit breakers or abort conditions

3. **Analysis**:
   - Review response effectiveness
   - Identify system weaknesses
   - Document unexpected behaviors
   - Plan improvements

### Game Day Scenarios

Common scenarios to test include:

- **Infrastructure Failure**: Server crashes, network partitions, zone outages
- **Dependency Failure**: Critical third-party service outage
- **Resource Exhaustion**: Memory leaks, disk space issues, connection pool saturation
- **Unexpected Load**: Traffic spikes, denial of service conditions
- **Data Corruption**: Invalid data propagating through the system

### Preparation Checklist

- ✅ Define success criteria
- ✅ Create a communication plan
- ✅ Schedule the event during normal business hours
- ✅ Have rollback procedures ready
- ✅ Notify stakeholders (but not necessarily all team members)
- ✅ Prepare monitoring dashboards
- ✅ Document the current system state

## Real-World Examples

### Netflix and the Amazon Reboot

During the "Great Amazon Reboot of 2014," Amazon needed to reboot nearly 10% of their EC2 instances for an emergency Xen security patch. Netflix, having extensively practiced chaos engineering, weathered this disruption remarkably well:

> "When we got the news about the emergency EC2 reboots, our jaws dropped. When we got the list of how many Cassandra nodes would be affected, I felt ill. Then I remembered all the Chaos Monkey exercises we've gone through. My reaction was, 'Bring it on!'"
> 
> — Christos Kalantzis, Netflix Cloud Database Engineering

Notably, Netflix staff weren't even in the office handling incidents during this event—they were at a company celebration, demonstrating the effectiveness of their resilience practices.

### Google DiRT (Disaster Recovery Testing)

Google conducts regular DiRT exercises to test their systems' resilience:

- Simulates major disasters across infrastructure
- Tests technical systems and human processes
- Uncovers unexpected dependencies
- Identifies areas for improvement in emergency procedures

One notable finding from DiRT exercises was a procedural gap: When data centers ran out of diesel for backup generators during a simulated disaster, employees didn't know the procedure for emergency purchases and had to use personal credit cards for large fuel purchases.

## Health Checks and Monitoring

Resilience depends on effective health monitoring to detect and respond to issues:

### Docker Health Checks

Docker provides built-in health check capabilities:

```yaml
# Example Docker Compose configuration with health check
services:
  webapp:
    image: my-web-app
    healthcheck:
      test: curl localhost:8080/health || exit 1
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

The `healthcheck` directive specifies:
- The command to run (`test`)
- How often to check (`interval`)
- How long to wait before timing out (`timeout`)
- How many failures to allow before marking unhealthy (`retries`)
- How long to wait before starting checks (`start_period`)

### Comprehensive Health Monitoring

Effective resilience requires monitoring at multiple levels:

1. **Infrastructure Health**: Physical and virtual resources
2. **Platform Health**: Kubernetes, databases, message queues
3. **Application Health**: Services, dependencies, business functions
4. **Business Health**: User activity, conversion rates, error rates

### Implementing Effective Health Endpoints

For microservices, implement health endpoints that provide:

- **Basic Health**: Simple up/down status
- **Dependency Status**: Status of external dependencies
- **Performance Metrics**: Response times, throughput
- **Resource Utilization**: Memory, CPU, connections

```javascript
// Example Express.js health check endpoint
app.get('/health', (req, res) => {
  const health = {
    uptime: process.uptime(),
    status: 'OK',
    timestamp: Date.now(),
    dependencies: {
      database: isDatabaseConnected ? 'OK' : 'FAIL',
      cache: isCacheConnected ? 'OK' : 'FAIL',
      messageQueue: isMessageQueueConnected ? 'OK' : 'FAIL'
    },
    metrics: {
      requestsPerMinute: calculateRequestRate(),
      averageResponseTime: calculateAverageResponseTime()
    }
  };
  
  const statusCode = Object.values(health.dependencies).includes('FAIL') ? 
    503 : 200;
  
  res.status(statusCode).json(health);
});
```

## Creating a Resilience Testing Strategy

Developing a comprehensive resilience testing strategy involves several components:

### 1. Baseline Current Resilience

- Document critical systems and dependencies
- Identify single points of failure
- Assess current recovery capabilities
- Define resilience metrics

### 2. Define Failure Scenarios

Create a catalog of potential failures based on:
- Historical incidents
- System architecture reviews
- Dependency analysis
- Threat modeling

### 3. Implement Testing Approaches

Combine multiple testing methods:
- **Synthetic Testing**: Controlled tests in non-production environments
- **Chaos Engineering**: Automated failure injection in production
- **Game Days**: Scheduled team exercises
- **Post-Mortem Learning**: Systematic analysis of real incidents

### 4. Build a Testing Cadence

Establish regular testing schedules:
- Daily automated chaos tests for critical components
- Weekly synthetic failure tests for key scenarios
- Monthly or quarterly game days for complex scenarios
- Immediate tests for new infrastructure or major changes

### 5. Continuous Improvement

Use test results to drive improvements:
- Update runbooks based on findings
- Enhance monitoring for detected blind spots
- Refactor systems to eliminate single points of failure
- Train teams on effective incident response

### Avoiding Cargo Cult Resilience

Be cautious about implementing resilience practices without clear justification:

> "Many companies jump on the idea of implementing high-availability, fault-tolerant and highly scalable systems... In Denmark most companies do not need this but there is a tendency to look at what the big companies are doing."

Always match your resilience strategy to your actual needs:
- Assess the true cost of downtime for your business
- Consider your team's operational capacity and expertise
- Implement appropriate complexity for your scale
- Focus on areas with the highest business impact
- Start small and iteratively improve your resilience practices

## Summary

System resilience engineering has evolved from reactive incident response to proactive testing and verification:

1. **Chaos Engineering** provides a systematic approach to testing system resilience by deliberately introducing controlled failures.

2. **Tools like Netflix's Simian Army and KubeInvaders** make it easier to implement chaos experiments, while even simple scripts can provide value for specific testing scenarios.

3. **Game Days** combine technical testing with human response, uncovering both system weaknesses and procedural gaps.

4. **Real-world examples from Netflix and Google** demonstrate the substantial value of resilience testing in preparing for actual incidents.

5. **Health checks and monitoring** form the foundation for detecting and responding to issues before they impact users.

6. **A comprehensive resilience strategy** combines multiple testing approaches with continuous improvement, while avoiding unnecessary complexity.

Remember that resilience testing should be approached carefully, with clear objectives and controlled blast radius. Start simple, focus on high-value areas, and gradually expand your testing as you build confidence and experience.

---

[<- Back: Kubernetes](./05-kubernetes.md) | [Next: Maintenance Best Practices ->](./07-maintenance.md)