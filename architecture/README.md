# Innovate Inc. — Architecture Design Document

## 1. Executive Summary
This document outlines the architectural strategy for Innovate Inc.’s web application. The design focuses on transforming a low-traffic MVP into a production-grade system capable of supporting millions of users through AWS managed services, Kubernetes orchestration, and cost-efficient scaling.

---

## 2. Cloud Environment Structure: The Landing Zone

To support Innovate Inc.’s growth and security requirements, we recommend a **multi-account strategy** managed via **AWS Control Tower**. This creates a **Landing Zone** that separates administrative overhead, development, and live production traffic.



### AWS Services (tools)

- **AWS Organizations**
  - The foundation used to create accounts and consolidate all billing into a single invoice.

- **AWS Control Tower**
  - The orchestration layer that automates account setup with pre-configured **Guardrails** (security rules).

- **AWS IAM Identity Center (SSO)**
  - The single entry point for users to log in and access different accounts based on their permissions.


### Account Breakdown & Purpose

| Account | Core Services Included | Purpose & Justification |
|--------|-------------------------|--------------------------|
| **Management** | AWS Organizations, AWS Billing, AWS IAM Identity Center (SSO) | The “Head Office”: Used strictly for billing and managing the other accounts. No application code or VPCs are deployed here to ensure the highest level of security. |
| **Shared Services** | Amazon ECR, GitHub Actions Runners, Transit Gateway | The “Tool Shed”: Centralizes shared resources. Docker images are stored in Amazon ECR here so they can be scanned once and deployed to both Dev and Prod. |
| **Development** | EKS (Small), RDS (Single-AZ), VPC | The “Playground”: A safe-to-fail environment where developers can test Python/React changes. Uses cheaper instance types to save costs during the “Low Load” phase. |
| **Production** | EKS (Large + Karpenter), RDS (Multi-AZ), CloudFront, WAF | The “Vault”: Handles live “millions of users” traffic. Isolated from Dev so testing bugs can’t crash production or leak sensitive data. |


---

## 3. Network Design

### Architecture: Multi-AZ Virtual Private Cloud (VPC)
We have designed a VPC across three Availability Zones (AZs) to ensure high availability and network partitioning.

- **Public Subnets**
  - House the Application Load Balancer (ALB) and NAT Gateways.

- **Private Application Subnets**
  - House the EKS worker nodes.
  - Nodes communicate with the internet only via NAT Gateways.

- **Private Data Subnets**
  - Strictly for RDS PostgreSQL.
  - No internet access; strictly restricted to traffic from application pods via Security Groups.

### Security Measures
- **AWS WAF**
  - Attached to the ALB to block SQL Injection, XSS, and DDoS attacks.
- **Network Isolation**
  - Sensitive data lives in isolated subnets with no route to the internet.

---

## 4. Compute Platform

### Service: Amazon EKS (Managed Kubernetes) with Karpenter

#### 4.1 Scaling & Resource Allocation
- **Karpenter Autoscaler**
  - We utilize Karpenter instead of standard node groups.
  - Watches for pending pods and provisions the optimal EC2 instance size/type in seconds.

- **Multi-Arch & Spot**
  - The cluster supports Spot Instances and Graviton (arm64) processors, reducing compute costs by up to 90%.

- **HPA (Horizontal Pod Autoscaling)**
  - Python pods scale horizontally based on traffic spikes before Karpenter triggers a node scale-up.

#### 4.2 Containerization & Deployment
- **Image Strategy**
  - Docker images are built as multi-arch (supporting both `amd64` and `arm64`).

- **Registry**
  - Images are stored in Amazon ECR with automated vulnerability scanning on push.

- **Deployment**
  - Helm is used for package management.
  - Rolling Updates are implemented to ensure zero-downtime during feature releases.

---

## 5. Database Strategy

### Service: Amazon RDS for PostgreSQL (Multi-AZ)
**Justification:** RDS removes the operational burden of patching and backups—critical for a startup with limited cloud experience.

- **High Availability**
  - A Multi-AZ deployment ensures a synchronous standby instance is always ready.
  - AWS performs an automatic failover if the primary instance fails.

### Scaling for Millions
- **Read Replicas**
  - Offload read-heavy traffic from the primary database to read replicas.

- **RDS Proxy**
  - Manages thousands of concurrent application connections to prevent PostgreSQL connection exhaustion.

### Disaster Recovery
- Automated daily snapshots with a **35-day retention period**
- Cross-region replication

---

## 7. CI/CD & Deployment

We aim for **Continuous Delivery** using **GitHub Actions** and **Helm**.

### Continuous Integration (CI)
- Code is tested on every change.
- The application is built into a **multi-arch Docker image** (`amd64` + `arm64`).
- The image is pushed to **Amazon ECR**.

### Continuous Delivery (CD)
- **Helm** deploys the new release to **EKS**.
- Helm triggers a **Rolling Update**.
- Kubernetes confirms the new version is healthy before terminating the old one, ensuring **zero downtime** for users.

---

## 8. Scalability Strategy: From 100 to 1,000,000 Users

This architecture is designed to be **elastic**, meaning it scales with traffic and **only costs what is necessary** for the current load.

### Cost-Efficiency at Start
- On Day 1, **Karpenter** provisions minimal, low-cost **Graviton** instances.
- We avoid over-provisioning by scaling only when metrics (CPU/RAM) demand it.

### Traffic Spike Resilience
- During rapid growth, **AWS CloudFront** caches the React SPA globally.
- This prevents millions of requests from reaching the backend.

### Database Survivability
- As traffic hits the millions:
  - **Amazon RDS Proxy** prevents PostgreSQL connection exhaustion.
  - **Read Replicas** offload read-heavy query volume from the primary database instance.

---