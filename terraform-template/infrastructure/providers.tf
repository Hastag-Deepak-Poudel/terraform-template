terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }

  backend "s3" {
    bucket                     = "chinmayto-terraform-state-bucket-1755526674"
    key                        = "eks-cluster-deep-dive/terraform.tfstate"
    region                     = "us-east-1"
    encrypt                    = true
    use_lockfile               = true
    skip_requesting_account_id = false
  }
}

################################################################################
# Configure the AWS Provider
################################################################################
provider "aws" {
  region = var.aws_region
}
