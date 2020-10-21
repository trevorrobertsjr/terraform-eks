variable "region" {
  default     = "us-east-1"
  description = "AWS region"
}

provider "aws" {
  version = ">= 2.28.1"
  region  = "us-east-1"
}

data "aws_availability_zones" "available" {}

locals {
  cluster_name = "training-eks-${random_string.suffix.result}"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.6.0"

  name                 = "training-vpc"
  cidr                 = "14.0.0.0/16"
  azs                  = ["us-east-1a", "us-east-1b", "us-east-1c"]
  # azs                  = data.aws_availability_zones.available.names
  private_subnets      = ["14.0.1.0/24", "14.0.2.0/24", "14.0.3.0/24"]
  public_subnets       = ["14.0.4.0/24", "14.0.5.0/24", "14.0.6.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}