resource "aws_security_group" "vm" {
  name   = "${var.name}-vm"
  vpc_id = aws_vpc.app.id
}

resource "aws_launch_template" "app" {
  name_prefix            = "${var.name}-"
  image_id               = "resolve:ssm:/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.vm.id]

  metadata_options {
    http_tokens = "required"
  }
}

resource "aws_instance" "app" {
  count     = var.vm_count
  subnet_id = element(aws_subnet.app[*].id, count.index)
  tags      = { Name = "${var.name}-vm-${count.index + 1}" }

  launch_template {
    id      = aws_launch_template.app.id
    version = tostring(aws_launch_template.app.latest_version)
  }
}
