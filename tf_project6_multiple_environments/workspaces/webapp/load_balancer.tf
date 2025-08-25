### ALB
resource "aws_security_group" "alb_sg" {
  name        = "${var.module_prefix}_alb_sg"
  vpc_id      = data.aws_vpc.default_vpc.id
  description = "Allow public HTTP requests to ALB"

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
  name               = "${var.module_prefix}alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [for subnet in data.aws_subnet.default_subnet : subnet.id]
  tags = {
    purpose = local.purpose_tag
  }
}

resource "aws_lb_target_group" "alb_tg" {
  name     = "${var.module_prefix}albtg"
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

