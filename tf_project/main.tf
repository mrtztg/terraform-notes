terraform {
  backend "s3" {
    bucket          = "morytsstate"
    key             = "tf-infra/tf.state"
    region          = "eu-west-2"
    use_lockfile    = true
    #dynamodb_table  = "tf-state-locking"
    encrypt         = true
  }
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
	region = "eu-west-2"
  profile = "terraform"
}

resource "aws_s3_bucket" "practice_s3" {
  bucket = "morys3practice"
}

resource "aws_instance" "practice_ec2" {
  ami = "ami-051fd0ca694aa2379"
  instance_type = "t3.micro"
}
