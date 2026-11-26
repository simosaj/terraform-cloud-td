variable "name" {
  description = "Préfixe des noms de ressources."
  type        = string
  default     = "td-cloud"
}

variable "dns_zone" {
  description = "Zone DNS privée, avec le point final."
  type        = string
  default     = "td.internal."
}

variable "vm_count" {
  description = "Nombre de VM à répartir entre deux zones."
  type        = number
  default     = 2
}

variable "region" {
  description = "Région européenne du TD."
  type        = string
  default     = "eu-west-3"
}
