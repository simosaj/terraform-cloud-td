resource "google_compute_network" "app" {
  name                    = "${var.name}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "app" {
  name          = "${var.name}-subnet"
  region        = var.region
  ip_cidr_range = "10.20.1.0/24"
  network       = google_compute_network.app.id
}
