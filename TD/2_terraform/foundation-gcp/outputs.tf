output "vpc_id" {
  description = "Identifiant du réseau."
  value       = module.foundation.vpc_id
}

output "vm_private_ips" {
  description = "Adresses privées des VM."
  value       = module.foundation.vm_private_ips
}

output "database_host" {
  description = "Adresse de MySQL dans le réseau privé."
  value       = module.foundation.database_host
}

output "app_dns" {
  description = "Nom DNS des VM."
  value       = module.foundation.app_dns
}
