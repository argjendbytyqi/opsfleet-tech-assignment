# Innovate Inc. Infrastructure (AWS + EKS)

This repository contains the infrastructure-as-code (IaC) to build a production-ready environment for our application. We use **Terraform** to ensure that our network, servers, and security settings are consistent and repeatable.

---

### 1. The Neighborhood (Networking)
We have built a **Virtual Private Cloud (VPC)** spread across **3 Availability Zones**. 
* **Why?** This is like having three different power grids. If one AWS data center has an outage, our app automatically stays running in the other two.

### 2. The Manager (Compute)
We use **Amazon EKS (Kubernetes) v1.31**. 
* **Why?** Instead of managing individual servers, we tell Kubernetes how many copies of our app we want, and it handles the rest.

### 3. The Smart Scaler (Karpenter)
We use **Karpenter** for "Just-in-Time" node provisioning.
* **Why?** Most systems use "Auto Scaling Groups" which are slow. Karpenter is smarter—it looks at our specific app needs and launches the exact right server size in seconds.

### 4. Cost Optimization (Spot & Graviton)
Our NodePool is configured to use:
* **Spot Instances:** These are "discount" servers from AWS that save us up to 90% in costs.
* **Graviton (arm64):** We use AWS's custom-built chips which are faster and cheaper than traditional Intel (x86) chips for Python/React workloads.

---

## Prerequisites

Before you start, ensure you have the following installed:
* [AWS CLI](https://aws.amazon.com/cli/) (Configured with your credentials)
* [Terraform](https://www.terraform.io/downloads)
* [kubectl](https://kubernetes.io/docs/tasks/tools/) (To talk to the cluster)
* [Helm](https://helm.sh/docs/intro/install/) (To install Kubernetes apps)

---

## Deployment Steps

### Step 1: Initialize and Build
This process takes about **15–30 minutes**. AWS is building a high-availability envrionment for your cluster during this time.

```bash
# Initialize Terraform and download plugins
terraform init

# Preview the changes (highly recommended!)
terraform plan

# Create the infrastructure (type 'yes' when prompted)
terraform apply 
```

### Step 2: Update your local access
After the cluster is ready, connect your local terminal:
```bash
aws eks update-kubeconfig --region eu-central-1 --name innovate-eks-cluster
```

### Step 3: Apply Karpenter Configuration
```bash
kubectl apply -f karpenter-config.yaml
```

---

## Cleanup and Deletion

To avoid orphaned resources and ensure a clean teardown, follow these steps in order:

1. **Delete Karpenter Nodes**
   Allow Karpenter to gracefully terminate its managed instances:
   ```bash
   kubectl delete -f karpenter-config.yaml
   ```

2. **Destroy Infrastructure**
   ```bash
   terraform destroy
   ```
