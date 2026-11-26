output "vpc_id" {
  description = "Identifiant du réseau."
  value       = google_compute_network.app.id
}

output "vm_private_ips" {
  description = "Adresses privées des VM."
  value       = google_compute_instance.app[*].network_interface[0].network_ip
}

output "database_host" {
  description = "Adresse de MySQL dans le réseau privé."
  value       = google_sql_database_instance.app.private_ip_address
}

output "app_dns" {
  description = "Nom DNS des VM."
  value       = google_dns_record_set.app.name
}
