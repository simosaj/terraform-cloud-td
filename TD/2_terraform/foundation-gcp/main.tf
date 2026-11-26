provider "google" {
  project = var.project_id
  region  = var.region
}

module "foundation" {
  source   = "../modules/gcp"
  name     = var.name
  region   = var.region
  dns_zone = var.dns_zone
  vm_count = var.vm_count
}
