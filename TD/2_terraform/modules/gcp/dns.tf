resource "google_dns_managed_zone" "app" {
  name       = "${var.name}-zone"
  dns_name   = var.dns_zone
  visibility = "private"

  private_visibility_config {
    networks {
      network_url = google_compute_network.app.id
    }
  }
}

resource "google_dns_record_set" "app" {
  managed_zone = google_dns_managed_zone.app.name
  name         = "app.${google_dns_managed_zone.app.dns_name}"
  type         = "A"
  ttl          = 60
  rrdatas      = google_compute_instance.app[*].network_interface[0].network_ip
}
