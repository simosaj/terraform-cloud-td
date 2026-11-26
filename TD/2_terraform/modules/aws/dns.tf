resource "aws_route53_zone" "app" {
  name = var.dns_zone
  vpc {
    vpc_id = aws_vpc.app.id
  }
}

resource "aws_route53_record" "app" {
  zone_id = aws_route53_zone.app.zone_id
  name    = "app.${var.dns_zone}"
  type    = "A"
  ttl     = 60
  records = aws_instance.app[*].private_ip
}
