terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws" # Specify the source of the AWS provider
      version = "~> 6.0"        # Use a version of the AWS provider that is compatible with version
    }
  }
}

locals {
  environment_name = "dev"
}

provider "aws" {
  region  = "eu-west-2" # Set the AWS region to US East (N. Virginia)
  profile = "terraform"
}

module "webapp" {
  source = "../webapp"
  ami_filter = {
    filter = "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"
    owner  = "099720109477"
  }
  db_config = {
    allocated_storage = 10,
    instance_type     = "db.t3.micro"
    db_name           = "${local.environment_name}_db"
  }
  db_credentials = {
    username = "${local.environment_name}_user"
    password = var.db_pass
  }
  ec2_instance_configs = [
    {
      instance_type = "t3.micro"
      tenancy       = "default"
    },
    {
      instance_type = "t3.nano"
      tenancy       = "default"
    }
  ]
  module_prefix   = "tfmory6${local.environment_name}"
  s3_bucket_name  = "morytf${local.environment_name}"
  create_dns_done = false # Because we handle this in "global" directory
  environment     = local.environment_name
  domain          = "10hidmort.xyz"
}

variable "db_pass" {
  type    = string
  default = "MyStrongPassword" # Just hardcoded for test
}
