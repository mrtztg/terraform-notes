terraform {
  # backend "s3" {
  #   bucket       = "morytfstate"
  #   key          = "tf_project/tf4.fstate"
  #   region       = "eu-west-2"
  #   use_lockfile = true
  # }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
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
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "ec2_instance_1" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  tenancy                = "default"
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  user_data = <<-EOF
            #!/bin/bash
            echo "Hello World 1" > index.html
            python3 -m http.server 8080 &
            EOF

  tags = {
    purpose = "practice"
  }
}

### EC2 instances
resource "aws_instance" "ec2_instance_2" {
  ami                    = data.aws_ami.ubuntu.id
  tenancy                = "default"
  instance_type          = "t3.nano"
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  user_data = <<-EOF
            #!/bin/bash
            echo "Hello world 2" > index.html
            python3 -m http.server 8080 &
            EOF

  tags = {
    purpose = "practice"
  }
}

### Security Groups

data "aws_vpc" "default_vpc" {
  default = true
}

resource "aws_security_group" "ec2_sg" {
  name        = "allow_alb"
  vpc_id      = data.aws_vpc.default_vpc.id
  description = "Allow traffic from ALB"

  tags = {
    purpose = "practice"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ec2_sg_inbound_ipv4" {
  security_group_id = aws_security_group.ec2_sg.id
  ip_protocol       = "tcp"
  from_port         = 8080
  to_port           = 8080
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "ec2_sg_inbound_ipv6" {
  security_group_id = aws_security_group.ec2_sg.id
  ip_protocol       = "tcp"
  from_port         = 8080
  to_port           = 8080
  cidr_ipv6         = "::/0"
}

resource "aws_vpc_security_group_egress_rule" "ec2_sg_outbound_ipv4" {
  security_group_id = aws_security_group.ec2_sg.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "ec2_sg_outbound_ipv6" {
  security_group_id = aws_security_group.ec2_sg.id
  ip_protocol       = "-1"
  cidr_ipv6         = "::/0"
}

### ALB
resource "aws_security_group" "alb_sg" {
  name        = "allow_http_alb"
  vpc_id      = data.aws_vpc.default_vpc.id
  description = "Allow public HTTP requessts to ALB"

  tags = {
    purpose = "practice"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_sg_inbound_ipv4" {
  security_group_id = aws_security_group.alb_sg.id
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "alb_sg_inbound_ipv6" {
  security_group_id = aws_security_group.alb_sg.id
  ip_protocol       = "tcp"
  to_port           = 80
  from_port         = 80
  cidr_ipv6         = "::/0"
}

resource "aws_vpc_security_group_egress_rule" "alb_sg_outbound_ipv4" {
  security_group_id = aws_security_group.alb_sg.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "alb_sg_outbound_ipv6" {
  security_group_id = aws_security_group.alb_sg.id
  ip_protocol       = "-1"
  cidr_ipv6         = "::/0"
}

data "aws_subnets" "default_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default_vpc.id]
  }
}

data "aws_subnet" "default_subnet" {
  for_each = toset(data.aws_subnets.default_subnets.ids)
  id       = each.value
}

resource "aws_lb" "alb" {
  name               = "tfalb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [for subnet in data.aws_subnet.default_subnet : subnet.id]
  tags = {
    purpose = "practice"
  }
}

resource "aws_lb_target_group" "alb_tg" {
  name        = "tfalbtg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default_vpc.id
}

resource "aws_lb_target_group_attachment" "alb_tg_attach_ec2_1" {
  target_group_arn = aws_lb_target_group.alb_tg.id
  target_id        = aws_instance.ec2_instance_1.id
  port             = 8080
  depends_on       = [aws_lb_target_group.alb_tg, aws_instance.ec2_instance_1]
}

resource "aws_lb_target_group_attachment" "alb_tg_attach_ec2_2" {
  target_group_arn = aws_lb_target_group.alb_tg.id
  target_id        = aws_instance.ec2_instance_2.id
  port             = 8080
  depends_on       = [aws_lb_target_group.alb_tg, aws_instance.ec2_instance_2]
}

resource "aws_lb_listener" "alb_all_route_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg.arn
  }
  depends_on = [ aws_lb.alb, aws_lb_target_group.alb_tg ]
  tags = {
    purpose = "practice"
  }
}

### S3 Bucket

resource "aws_s3_bucket" "bucket" {
  bucket        = "morytf4bucket"
  force_destroy = true
  tags = {
    purpose = "practice"
  }
}

resource "aws_s3_bucket_versioning" "bucket_versioning" {
  bucket = aws_s3_bucket.bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_encryption" {
  bucket = aws_s3_bucket.bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
