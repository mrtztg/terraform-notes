terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

module "webapp1" {
  source = "./webapp"
  db_config = {
    db_name           = "myowndb1"
    instance_type     = "db.t3.micro"
    allocated_storage = 10
  }
  ami_filter = {
    filter = "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"
    owner  = "099720109477"
  }
  db_credentials = {
    password = "MyVeryStrongPASS"
    username = "MoryUser"
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
  s3_bucket_name = "morytfproject5a"
  alb_security_group_name = "alb_sg_webapp1"
  ec2_security_group_name = "ec2_sg_webapp1"
}

module "webapp2" {
  source = "./webapp"

  db_config = {
    db_name           = "myowndb2"
    instance_type     = "db.t3.micro"
    allocated_storage = 10
  }
  ami_filter = {
    filter = "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"
    owner  = "099720109477"
  }
  db_credentials = {
    password = "MyVeryStrongPASS"
    username = "MoryUser"
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
  s3_bucket_name = "morytfproject5b"
  alb_security_group_name = "alb_sg_webapp2"
  ec2_security_group_name = "ec2_sg_webapp2"
}
