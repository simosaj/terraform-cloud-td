resource "aws_vpc" "app" {
  cidr_block           = "10.30.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = { Name = "${var.name}-vpc" }
}

resource "aws_subnet" "app" {
  count             = 2
  vpc_id            = aws_vpc.app.id
  availability_zone = var.zones[count.index]
  cidr_block        = cidrsubnet(aws_vpc.app.cidr_block, 8, count.index + 1)
  tags              = { Name = "${var.name}-subnet-${count.index + 1}" }
}
