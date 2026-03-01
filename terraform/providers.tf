terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.33.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.15"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.31"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
  default_tags {
    tags = {
      Environment = "InnovateInc-POC"
      Project     = "Opsfleet-Assignment"
    }
  }
}