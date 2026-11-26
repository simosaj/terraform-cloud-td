resource "google_compute_global_address" "sql_range" {
  name          = "${var.name}-sql-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.app.id
}

resource "google_service_networking_connection" "sql" {
  network                 = google_compute_network.app.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.sql_range.name]
}

resource "google_sql_database_instance" "app" {
  name             = "${var.name}-mysql"
  database_version = "MYSQL_8_0"
  region           = var.region
  depends_on       = [google_service_networking_connection.sql]

  settings {
    tier    = "db-f1-micro"
    edition = "ENTERPRISE"
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.app.id
    }
  }
  deletion_protection = false
}
