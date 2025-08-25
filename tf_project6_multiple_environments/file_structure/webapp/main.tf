
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

locals {
  purpose_tag = "practice"
}

provider "aws" {
  region  = var.region
  profile = var.aws_profile
}
