terraform {
  backend "s3" {
    bucket       = "morytfstate"
    key          = "tf_project/tf.tfstate"
    region       = "eu-west-2"
    use_lockfile = true
  }

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region  = var.region
  profile = var.aws_profile
}

resource "aws_instance" "tf4_ec2" {
  ami = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  tenancy = "default"

  tags = {
    purpose = "practice"
  }
}

resource "aws_s3_bucket" "tf4_s3" {
  bucket = "morytf4bucket"
  tags = {
    purpose = "practice"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  
  filter {
    name = "name"
    values = [ "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*" ]
  }

  owners = [ "099720109477" ] # Canonical
}