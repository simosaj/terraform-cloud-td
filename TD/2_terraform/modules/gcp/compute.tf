resource "google_compute_instance" "app" {
  count        = var.vm_count
  name         = "${var.name}-vm-${count.index + 1}"
  machine_type = "e2-micro"
  zone         = "${var.region}-${element(["a", "b"], count.index)}"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 10
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.app.id
  }
}
