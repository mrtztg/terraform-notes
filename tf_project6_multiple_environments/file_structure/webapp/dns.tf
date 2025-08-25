#Route53
resource "aws_route53_zone" "primary" {
  count = var.create_dns_done ? 1 : 0
  name  = var.domain
  tags = {
    purpose = local.purpose_tag
  }
}

data "aws_route53_zone" "primary" {
  count = var.create_dns_done ? 0 : 1
  name  = var.domain
}

resource "aws_route53_record" "root" {
  zone_id = var.create_dns_done ? aws_route53_zone.primary[0].id : data.aws_route53_zone.primary[0].id
  name    = var.create_dns_done ? var.domain : "${var.environment}.${var.domain}"
  type    = "A"
  alias {
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
    evaluate_target_health = true
  }
}
