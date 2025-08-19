terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws" # Specify the source of the AWS provider
      version = "~> 6.0"        # Use a version of the AWS provider that is compatible with version
    }
  }
}

provider "aws" {
  region = "eu-west-2"
  profile = "terraform"
}

#Route53
resource "aws_route53_zone" "primary" {
  name  = "10hidmort.xyz"
}
