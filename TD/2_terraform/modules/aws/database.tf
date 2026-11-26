resource "aws_security_group" "db" {
  name   = "${var.name}-db"
  vpc_id = aws_vpc.app.id
}

resource "aws_vpc_security_group_ingress_rule" "mysql" {
  security_group_id            = aws_security_group.db.id
  referenced_security_group_id = aws_security_group.vm.id
  ip_protocol                  = "tcp"
  from_port                    = 3306
  to_port                      = 3306
}

resource "aws_vpc_security_group_egress_rule" "mysql" {
  security_group_id            = aws_security_group.vm.id
  referenced_security_group_id = aws_security_group.db.id
  ip_protocol                  = "tcp"
  from_port                    = 3306
  to_port                      = 3306
}

resource "aws_db_subnet_group" "app" {
  name       = "${var.name}-db"
  subnet_ids = aws_subnet.app[*].id
}

resource "aws_db_instance" "app" {
  identifier                  = "${var.name}-mysql"
  engine                      = "mysql"
  instance_class              = "db.t4g.micro"
  allocated_storage           = 20
  storage_encrypted           = true
  username                    = "tdadmin"
  manage_master_user_password = true
  publicly_accessible         = false
  db_subnet_group_name        = aws_db_subnet_group.app.name
  vpc_security_group_ids      = [aws_security_group.db.id]
  skip_final_snapshot         = true
}
