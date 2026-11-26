variable "project_id" {
  description = "Projet GCP fourni localement via TF_VAR_project_id."
  type        = string
}

variable "vm_count" {
  type    = number
  default = 2
}

provider "google" {
  project = var.project_id
  region  = "europe-west9"
}

module "foundation" {
  source   = "../modules/gcp"
  vm_count = var.vm_count
}
