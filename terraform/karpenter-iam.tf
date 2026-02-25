module "karpenter" {
  source = "terraform-aws-modules/eks/aws//modules/karpenter"

  cluster_name = module.eks.cluster_name

  create_node_iam_role = true
  create_access_entry  = true

  create_iam_role      = true
  
  enable_spot_termination = true

}