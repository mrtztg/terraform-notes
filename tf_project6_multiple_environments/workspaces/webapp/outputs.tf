# output "domain_nameservers" {
#   value = aws_route53_zone.primary.name_servers
# }

output "instances_ip" {
  value = "Instances IPs:${aws_instance.ec2_instance_1.public_ip},${aws_instance.ec2_instance_2.public_ip}"
}

output "db_ip" {
  value = "IP: ${aws_db_instance.db.address}"
}

output "alb_dns" {
  value = aws_lb.alb.dns_name
}