output "vpc_id" {
  description = "Identifiant du réseau."
  value       = aws_vpc.app.id
}

output "vm_private_ips" {
  description = "Adresses privées des VM."
  value       = aws_instance.app[*].private_ip
}

output "database_host" {
  description = "Adresse de MySQL dans le réseau privé."
  value       = aws_db_instance.app.address
}

output "app_dns" {
  description = "Nom DNS des VM."
  value       = aws_route53_record.app.fqdn
}
