terraform {
  backend "s3" {
    bucket       = "morytfstate"
    key          = "tf_project/tf4.fstate"
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

data "aws_ami" "ubuntu" {
  most_recent = true
  
  filter {
    name = "name"
    values = [ "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*" ]
  }

  owners = [ "099720109477" ] # Canonical
}

resource "aws_instance" "tf4_ec2" {
  ami = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  tenancy = "default"

  user_data = <<-EOF
            #!/bin/bash
            echo "Hello World 1" > index.html
            python3 -m http.server 8080 &
            EOF

  tags = {
    purpose = "practice"
  }
}

data "aws_vpc" "default_vpc" {
  default = true
}

data

resource "aws_instance" "tf4_ec2_2" {
  ami = data.aws_ami.ubuntu.id
  tenancy = "default"
  instance_type = "t3.nano"

  user_data = <<-EOF
              #!/bin/bash
              echo 'Hello world 2" > index.html
              python3 -m http.server 8080 &
              EOF
}

resource "aws_s3_bucket" "tf4_s3" {
  bucket = "morytf4bucket"
  force_destroy = true
  tags = {
    purpose = "practice"
  }
}

resource "aws_s3_bucket_versioning" "tf4_s3_versioning" {
  bucket = aws_s3_bucket.tf4_s3.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf4_s3_encryption" {
  bucket = aws_s3_bucket.tf4_s3.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
