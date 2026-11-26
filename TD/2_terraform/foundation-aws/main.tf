provider "aws" {
  region = var.region
}

module "foundation" {
  source   = "../modules/aws"
  name     = var.name
  dns_zone = var.dns_zone
  vm_count = var.vm_count
  zones    = ["${var.region}a", "${var.region}b"]
}
