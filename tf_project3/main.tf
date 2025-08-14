terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region  = var.region
  profile = "terraform"
}

resource "aws_instance" "mory_practice3_ec2" {
  ami           = "ami-051fd0ca694aa2379"
  instance_type = var.ec2_type
}

output "instance_id" {
  value = aws_instance.mory_practice3_ec2.id
}
