variable "vm_count" {
  type    = number
  default = 2
}

provider "aws" {
  region = "eu-west-3"
}

module "foundation" {
  source   = "../modules/aws"
  vm_count = var.vm_count
}
