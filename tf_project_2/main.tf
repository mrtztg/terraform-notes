terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region  = "eu-west-2"
  profile = "terraform"
}

resource "aws_vpc" "mory_practice2_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    purpose = "tf_practice"
  }
}

resource "aws_subnet" "mory_practice2_subnet" {
  vpc_id            = aws_vpc.mory_practice2_vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "eu-west-2a"

  tags = {
    purpuse = "tf_practice"
  }
}

resource "aws_network_interface" "mory_practice2_ni" {
  subnet_id = aws_subnet.mory_practice2_subnet.id
  tags = {
    purpuse = "tf_practice"
  }
  security_groups = [
    aws_security_group.mory_practice2_allow_http.id
  ]
}

resource "aws_security_group" "mory_practice2_allow_http" {
  name   = "allow_http"
  vpc_id = aws_vpc.mory_practice2_vpc.id
  tags = {
    purpuse = "tf_practice"
  }
}

resource "aws_vpc_security_group_ingress_rule" "mory_practice2_allow_http_ipv4" {
  security_group_id = aws_security_group.mory_practice2_allow_http.id
  cidr_ipv4         = aws_vpc.mory_practice2_vpc.cidr_block
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

# resource "aws_vpc_security_group_ingress_rule" "mory_practice2_allow_http_ipv6" {
#   security_group_id = aws_vpc.mory_practice2_vpc.id
#   cidr_ipv6         = aws_vpc.mory_practice2_vpc.ipv6_cidr_block
#   ip_protocol       = "tcp"
#   from_port         = 80
#   to_port           = 80
# }

resource "aws_vpc_security_group_egress_rule" "mory_practice2_allow_all_egress_ipv4" {
  security_group_id = aws_vpc.mory_practice2_vpc.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# resource "aws_vpc_security_group_egress_rule" "mory_practice2_allow_all_egress_ipv6" {
#   security_group_id = aws_vpc.mory_practice2_vpc.id
#   cidr_ipv6         = "::/0"
#   ip_protocol       = "-1"
# }

resource "aws_instance" "mory_practice2_ec2" {
  ami           = "ami-051fd0ca694aa2379"
  instance_type = "t3.micro"
  depends_on = [
    aws_security_group.mory_practice2_allow_http,
    aws_vpc.mory_practice2_vpc
  ]
  network_interface {
    network_interface_id = aws_network_interface.mory_practice2_ni.id
    device_index         = 0
  }
  tags = {
    purpuse = "tf_practice"
  }
}
