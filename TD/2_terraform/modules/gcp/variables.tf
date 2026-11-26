variable "name" {
  description = "Préfixe court et unique des ressources."
  type        = string
  default     = "td-cloud"
}

variable "dns_zone" {
  type    = string
  default = "td.internal."
}

variable "vm_count" {
  type    = number
  default = 2
  validation {
    condition     = var.vm_count >= 1 && var.vm_count == floor(var.vm_count)
    error_message = "Le nombre de VM doit être un entier positif."
  }
}

variable "region" {
  type    = string
  default = "europe-west9"
}
