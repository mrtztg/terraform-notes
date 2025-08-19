#
# #Route53
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
