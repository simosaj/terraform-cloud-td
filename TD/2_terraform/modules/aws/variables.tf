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

variable "zones" {
  description = "Deux zones distinctes de la région du provider AWS."
  type        = list(string)
  default     = ["eu-west-3a", "eu-west-3b"]
  validation {
    condition     = length(var.zones) == 2 && length(distinct(var.zones)) == 2
    error_message = "Fournir deux zones distinctes."
  }
}
