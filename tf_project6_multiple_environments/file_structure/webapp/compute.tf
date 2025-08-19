

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
  name        = "${var.module_prefix}_ec2_sg"
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
