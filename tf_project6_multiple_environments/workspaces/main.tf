terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  profile = "terraform"
  region  = "eu-west-2"
}

locals {
  environment_name = terraform.workspace
}

module "web-app" {
  source = "./webapp"
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
  create_dns_done = local.environment_name == "production"
  environment     = local.environment_name
  domain = "10hidmort.xyz"
}

variable "db_pass" {
  type      = string
  sensitive = true
}
