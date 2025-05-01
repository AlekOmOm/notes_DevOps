# 3. Deployment Strategies ⚡

[<- Back: Infrastructure and Configuration](./02-infrastructure-configuration.md) | [Next: Orchestration Fundamentals ->](./04-orchestration.md)

## Table of Contents

- [Introduction](#introduction)
- [Key Considerations](#key-considerations)
- [Big Bang Deployment](#big-bang-deployment)
- [Blue-Green Deployment](#blue-green-deployment)
- [Canary Deployment](#canary-deployment)
- [Rolling Updates](#rolling-updates)
- [Shadow Deployment](#shadow-deployment)
- [Real-World Examples](#real-world-examples)
- [Comparing Strategies](#comparing-strategies)
- [Summary](#summary)

## Introduction

Deployment strategies define how new versions of an application are released to production. The right strategy balances several factors: minimizing downtime, managing risk, providing rollback capabilities, and optimizing resource usage. As applications become more critical to business operations, the way we deploy them has evolved from simple all-at-once approaches to sophisticated progressive delivery techniques.

## Key Considerations

When selecting a deployment strategy, several factors should be considered:

### Zero Downtime

Modern users expect services to be available 24/7. Deployment strategies that minimize or eliminate downtime are increasingly important for user satisfaction and business continuity.

### Scalability

As application usage grows, deployment strategies must scale accordingly, handling larger infrastructure footprints and more complex application architectures.

### Downtime Tolerance

Different applications have different requirements:
- **Mission-critical systems** (e.g., payment processing): Cannot tolerate any downtime
- **Internal tools**: May accept brief maintenance windows
- **Batch processing systems**: May have natural deployment windows between processing runs

### Rollback Plan

The ability to quickly revert to a previous version if problems emerge is essential for reducing the impact of failed deployments.

### Cost Efficiency

Some strategies require additional infrastructure during deployments, increasing costs. This must be balanced against the business impact of potential downtime.

## Big Bang Deployment

The simplest deployment strategy involves replacing the entire application at once.

### How It Works

1. Take the application offline (maintenance mode)
2. Deploy the new version
3. Verify functionality
4. Bring the application back online

### Advantages

- Simple to implement
- No complexity in managing multiple versions
- Complete deployment in a single operation

### Disadvantages

- Requires downtime
- High risk – if something fails, all users are affected
- Complex rollbacks may require additional downtime

### When to Use

- For development or testing environments
- Non-critical internal applications
- Applications with planned maintenance windows
- Simple applications with quick deployment times

## Blue-Green Deployment

Blue-Green deployment uses two identical environments, only one of which serves production traffic at any time.

### How It Works

1. Start with "Blue" environment serving production traffic
2. Deploy new version to "Green" environment
3. Test the Green environment thoroughly
4. Switch traffic from Blue to Green (typically using a load balancer or DNS change)
5. Keep Blue environment available for quick rollback if needed

```javascript
// Simplified example of blue-green switching with AWS Route 53
resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.example.com"
  type    = "A"
  
  alias {
    name                   = var.active_environment == "blue" ? 
                              aws_elb.blue.dns_name : aws_elb.green.dns_name
    zone_id                = var.active_environment == "blue" ? 
                              aws_elb.blue.zone_id : aws_elb.green.zone_id
    evaluate_target_health = true
  }
}
```

### Database Considerations

Database changes add complexity to blue-green deployments. Two common approaches:

1. **Separate Blue/Green Databases**: Maintain two databases and migrate data during deployment
   - Advantages: Clean separation, simpler rollback
   - Disadvantages: Data duplication, complex data migration

2. **Shared Database with Schema Management**: Both environments use the same database, with careful schema evolution
   - Advantages: No data duplication, simpler data consistency
   - Disadvantages: More complex deployment planning, careful schema versioning required

### Advantages

- Zero downtime deployments
- Simple and fast rollback (just switch back to Blue)
- Full testing of the new version in a production-like environment
- Reduced deployment risk

### Disadvantages

- Requires twice the infrastructure during deployment
- Database changes require special handling
- Higher cost due to duplicate infrastructure

### When to Use

- Production applications that can't afford downtime
- When simple rollback capability is required
- When thorough pre-production testing is needed in an identical environment

## Canary Deployment

Canary deployment gradually rolls out changes to a subset of users before deploying to the entire infrastructure.

### How It Works

1. Deploy the new version to a small subset of servers (e.g., 5-10%)
2. Direct a small percentage of user traffic to these servers
3. Monitor performance, errors, and user feedback
4. Gradually increase traffic to the new version if no issues are detected
5. If problems occur, rollback by redirecting all traffic to the old version

```javascript
// Example of canary configuration in Nginx
upstream backend {
    server backend-v1.example.com weight=90;
    server backend-v2.example.com weight=10;  # Canary gets 10% of traffic
}

server {
    listen 80;
    location / {
        proxy_pass http://backend;
    }
}
```

### Advantages

- Reduces risk by limiting impact of problems
- Provides real user feedback with limited exposure
- Allows for performance testing under real-world conditions
- Can be targeted to specific user segments

### Disadvantages

- More complex to set up than blue-green
- Requires sophisticated traffic routing
- Users may have inconsistent experiences during rollout
- Monitoring needs to be more sophisticated

### When to Use

- For high-risk changes or major feature updates
- Applications with diverse user bases where impact can be tested on a subset
- When real-world validation is needed beyond pre-production testing

## Rolling Updates

Rolling updates deploy the new version incrementally across the infrastructure, updating servers one by one or in small batches.

### How It Works

1. Take a subset of servers out of rotation (often one at a time)
2. Deploy new version to these servers
3. Put updated servers back into rotation
4. Repeat until all servers are updated

### Ramped Deployment Variation

A variation called "ramped deployment" increases the percentage more aggressively:
- Start with 10% of servers
- Then update 30%
- Then update 60%
- Finally update 100%

This accelerates deployment while still limiting risk compared to big bang deployment.

### Advantages

- No additional infrastructure required
- Controlled, gradual rollout
- Resource usage remains consistent
- Works well with auto-scaling

### Disadvantages

- Deployment takes longer to complete
- Multiple versions run simultaneously, which may cause consistency issues
- Rollback is more complex than blue-green
- Health checks are critical to prevent routing to partially-updated servers

### When to Use

- When additional infrastructure for blue-green is too costly
- For applications designed to handle running multiple versions simultaneously
- In auto-scaling environments where instance count fluctuates

## Shadow Deployment

Shadow deployment (also called "dark launching") runs the new version in parallel with the production version, but only the current production version serves real user traffic.

### How It Works

1. Deploy the new version alongside the existing version
2. Duplicate real production traffic to the new version
3. The new version processes requests but its responses are discarded
4. Monitor how the new version performs against real traffic
5. Switch to the new version once confidence is established

```javascript
// Simplified example of shadow deployment logic
function handleRequest(request) {
  // Process with current production version
  const productionResponse = productionSystem.process(request);
  
  // Also send to new version, but don't use the response
  try {
    newVersionSystem.process(request)
      .then(newResponse => {
        // Log and compare responses, but don't return to user
        compareResponses(productionResponse, newResponse);
      })
      .catch(error => {
        // Log errors for analysis
        logShadowError(error);
      });
  } catch (e) {
    // Ensure errors in shadow system don't affect production
  }
  
  // Only return the production response to users
  return productionResponse;
}
```

### Frontend Feature Toggling

For frontend applications, a similar approach called "feature toggling" deploys code with new features disabled. Features can be enabled for:
- Internal employees only
- A small percentage of users
- Specific geographic regions
- Particular user segments

### Advantages

- Zero risk to user experience
- Allows testing with real production traffic
- Enables performance testing at scale
- Uncovers issues that might not appear in test environments

### Disadvantages

- Requires infrastructure to duplicate traffic
- Complex to implement, especially for stateful applications
- Shadow version must avoid affecting external systems (payments, emails, etc.)

### When to Use

- High-risk changes to critical systems
- Performance-sensitive updates
- When synthetic testing isn't sufficient to validate behavior

## Real-World Examples

### Facebook's Release Process

Facebook employs a sophisticated deployment approach:

1. **Internal Deployment**: Changes are first deployed to servers that only serve Facebook employees
2. **Limited Deployment**: After passing internal validation, changes go to a small percentage of customer-facing servers
3. **Full Deployment**: Finally, changes roll out to all production servers

Facebook Gatekeeper, an internal tool, manages this process and can target releases to specific demographic groups or regions.

### Other Notable Tools

- **Etsy Feature API**: Enables gradual feature rollout with fine-grained control
- **Netflix Archaius**: Provides dynamic property management for feature flags and configuration

## Comparing Strategies

| Strategy | Downtime | Risk | Resource Needs | Rollback Speed | Implementation Complexity |
|----------|----------|------|----------------|----------------|---------------------------|
| Big Bang | High | High | Low | Slow | Low |
| Blue-Green | None | Medium | High | Fast | Medium |
| Canary | None | Low | Medium | Fast | High |
| Rolling Update | Minimal | Medium | Low | Medium | Medium |
| Shadow | None | Very Low | High | N/A | Very High |

## Summary

Deployment strategies have evolved from simple, high-risk approaches to sophisticated techniques that prioritize availability and safety. Key takeaways include:

1. Each strategy involves trade-offs between downtime, risk, resource usage, and complexity.

2. Blue-Green deployment offers a good balance of safety and simplicity for many applications.

3. Canary deployments provide additional risk reduction by limiting user exposure.

4. Rolling updates are resource-efficient but require applications that can handle multiple simultaneous versions.

5. Shadow deployments and feature toggling enable risk-free testing with real traffic.

The best strategy depends on your specific requirements, including downtime tolerance, infrastructure resources, and application architecture. Many organizations use different strategies for different applications or even combine multiple approaches for critical systems.

---

[<- Back: Infrastructure and Configuration](./02-infrastructure-configuration.md) | [Next: Orchestration Fundamentals ->](./04-orchestration.md)
