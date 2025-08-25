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

locals {
  purpose_tag = "practice"
}

provider "aws" {
  region  = var.region
  profile = var.aws_profile
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = [var.ami_filter.filter]
  }

  owners = [var.ami_filter.owner] # Canonical
}

resource "aws_instance" "ec2_instance_1" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.ec2_instance_configs[0].instance_type
  tenancy                = var.ec2_instance_configs[0].tenancy
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  user_data = <<-EOF
            #!/bin/bash
            echo "Hello World 1" > index.html
            python3 -m http.server ${var.ec2_port} &
            EOF

  tags = {
    purpose = local.purpose_tag
  }
}

### EC2 instances
resource "aws_instance" "ec2_instance_2" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.ec2_instance_configs[1].instance_type
  tenancy                = var.ec2_instance_configs[1].tenancy
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  user_data = <<-EOF
            #!/bin/bash
            echo "Hello world 2" > index.html
            python3 -m http.server ${var.ec2_port} &
            EOF

  tags = {
    purpose = local.purpose_tag
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
    purpose = local.purpose_tag
  }
}

resource "aws_vpc_security_group_ingress_rule" "ec2_sg_inbound_ipv4" {
  security_group_id = aws_security_group.ec2_sg.id
  ip_protocol       = "tcp"
  from_port         = var.ec2_port
  to_port           = var.ec2_port
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "ec2_sg_inbound_ipv6" {
  security_group_id = aws_security_group.ec2_sg.id
  ip_protocol       = "tcp"
  from_port         = var.ec2_port
  to_port           = var.ec2_port
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
    purpose = local.purpose_tag
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
    purpose = local.purpose_tag
  }
}

resource "aws_lb_target_group" "alb_tg" {
  name     = "tfalbtg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default_vpc.id
  health_check {
    enabled  = true
    path     = "/"
    port     = var.ec2_port
    protocol = "HTTP"
    interval = "10"
    timeout  = 3
  }
}

resource "aws_lb_target_group_attachment" "alb_tg_attach_ec2_1" {
  target_group_arn = aws_lb_target_group.alb_tg.id
  target_id        = aws_instance.ec2_instance_1.id
  port             = var.ec2_port
  depends_on       = [aws_lb_target_group.alb_tg, aws_instance.ec2_instance_1]
}

resource "aws_lb_target_group_attachment" "alb_tg_attach_ec2_2" {
  target_group_arn = aws_lb_target_group.alb_tg.id
  target_id        = aws_instance.ec2_instance_2.id
  port             = var.ec2_port
  depends_on       = [aws_lb_target_group.alb_tg, aws_instance.ec2_instance_2]
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  # default_action {
  #   type             = "forward"
  #   target_group_arn = aws_lb_target_group.alb_tg.arn
  # }

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found!!"
      status_code  = "404"
    }
  }

  depends_on = [aws_lb.alb, aws_lb_target_group.alb_tg]
  tags = {
    purpose = local.purpose_tag
  }
}

resource "aws_lb_listener_rule" "index_page" {
  listener_arn = aws_lb_listener.alb_listener.arn
  priority     = 100
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg.arn
  }
  condition {
    path_pattern {
      values = ["/"]
    }
  }
  tags = {
    purpose = local.purpose_tag
  }
}

# Route53
# resource "aws_route53_zone" "primary" {
#   name = "10hidmort.xyz"
#   tags = {
#     purpose = local.purpose_tag
#   }
# }
#
# resource "aws_route53_record" "root" {
#   zone_id = aws_route53_zone.primary.id
#   name    = "alb.10hidmort.xyz"
#   type    = "A"
#   alias {
#     name                   = aws_lb.alb.dns_name
#     zone_id                = aws_lb.alb.zone_id
#     evaluate_target_health = true
#   }
# }

### S3 Bucket
resource "aws_s3_bucket" "bucket" {
  bucket        = var.s3_bucket_name
  force_destroy = true
  tags = {
    purpose = local.purpose_tag
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

### RDS Instance

data "aws_rds_engine_version" "db_cluster" {
  engine = "postgres"
}

resource "aws_db_instance" "db" {
  allocated_storage   = var.db_config.allocated_storage
  db_name             = var.db_config.db_name
  engine              = "postgres"
  engine_version      = data.aws_rds_engine_version.db_cluster.version
  instance_class      = var.db_config.instance_type
  username            = var.db_credentials.username
  password            = var.db_credentials.password
  skip_final_snapshot = true
  tags = {
    purpose = local.purpose_tag
  }
}
