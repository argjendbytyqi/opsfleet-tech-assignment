locals {
  name   = "innovate-eks-cluster"
  region = "eu-central-1"
  vpc_cidr = "10.0.0.0/16"
  azs      = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
   version = "6.6.0"

  name = "${local.name}-vpc"
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Tags needed for Karpenter to discover subnets above!
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
    "karpenter.sh/discovery"          = local.name
  }

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }
}