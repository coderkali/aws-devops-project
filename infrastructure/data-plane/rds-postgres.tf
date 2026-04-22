resource "aws_db_instance" "postgres" {
  identifier        = "devops-postgres"
  engine            = "postgres"
  engine_version = "15.12"
  instance_class    = var.db_instance_class
  allocated_storage = 20

  db_name  = "orders"
  username = jsondecode(data.aws_secretsmanager_secret_version.db_credentials.secret_string)["username"]
  password = jsondecode(data.aws_secretsmanager_secret_version.db_credentials.secret_string)["password"]

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  skip_final_snapshot = true
  multi_az            = false

  tags = {
    Name = "devops-postgres"
  }
}