resource "local_file" "karpenter_config" {
  content = templatefile("${path.module}/karpenter-config.tftpl", {
    node_role_name = module.karpenter.node_iam_role_name
    cluster_name   = module.eks.cluster_name
  })
  filename = "${path.module}/karpenter-config.yaml"
}