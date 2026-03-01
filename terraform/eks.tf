module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.15.1"

  name               = local.name
  kubernetes_version = "1.31"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  authentication_mode                      = "API"
  enable_cluster_creator_admin_permissions = true
  endpoint_public_access                   = true
  endpoint_private_access                  = true

  # EKS Managed Addons - required for node health with AL2023
  addons = {
    coredns    = { most_recent = true }
    kube-proxy = { most_recent = true }
    vpc-cni = {
      most_recent    = true
      before_compute = true # Initialize CNI before nodes launch
    }
  }

  # The EKS module manages necessary security group rules by default.
  # We only add node-to-node connectivity and egress here.
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description = "Node all egress"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "egress"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  # We create a small EKS Managed Node Group so the cluster has nodes immediately.
  eks_managed_node_groups = {
    karpenter = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t3.medium"]
      min_size       = 2
      max_size       = 3
      desired_size   = 2

      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 2
      }

      iam_role_additional_policies = {
        AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      }
    }
  }
}
