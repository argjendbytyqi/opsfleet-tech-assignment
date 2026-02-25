# Terraform Infrastructure

## Design Decisions
* **Networking:** A dedicated VPC with 3 Availability Zones to ensure high availability.
* **Compute:** Amazon EKS v1.31 utilizing Karpenter for node provisionong.
* **Scaling:** Configured a NodePool to utilize **Spot instances** and support both **x86 (amd64)** and **Graviton (arm64)** architectures for cost and performance optimization.

## Prerequisites
* AWS CLI configured with appropriate permissions.
* `kubectl` and `helm`.

## Deployment Steps
1. **Initialize and Apply:**
   ```bash
   terraform init
   terrplan plan
   terraform apply

2. **Update and Deploy Karpenter Configuration:**
    ```bash
    aws eks update-kubeconfig --region us-east-1 --name innovate-eks-cluster

    kubectl apply -f karpenter-config.yaml