module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.15.1"

  name             = local.name
  kubernetes_version = "1.35"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  enable_cluster_creator_admin_permissions = true

  # We create a small EKS Managed Node Group so the cluster has nodes immediately.
  # This is required because Karpenter runs as pods, and pods need nodes to start.
  # Once Karpenter is running, it can provision additional nodes on demand.
  eks_managed_node_groups = {
    karpenter = {
      instance_types = ["t2.small"]
      min_size     = 2
      max_size     = 3
      desired_size = 2
    }
  }
}

module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "21.15.1"

  cluster_name = module.eks.cluster_name

  # Determines whether to create pod identity association for Karpenter, which allows it to assume the necessary IAM roles for provisioning nodes.
  create_pod_identity_association = true
  create_node_iam_role = true
  
  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
}