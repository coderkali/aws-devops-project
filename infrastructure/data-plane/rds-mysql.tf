resource "aws_db_subnet_group" "main" {
  name       = "devops-db-subnet-group"
  subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnet_ids

  tags = {
    Name = "devops-db-subnet-group"
  }
}

resource "aws_db_instance" "mysql" {
  identifier        = "devops-mysql"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = var.db_instance_class
  allocated_storage = 20

  db_name  = "catalog"
  username = jsondecode(data.aws_secretsmanager_secret_version.db_credentials.secret_string)["username"]
  password = jsondecode(data.aws_secretsmanager_secret_version.db_credentials.secret_string)["password"]

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  skip_final_snapshot = true
  multi_az            = false

  tags = {
    Name = "devops-mysql"
  }
}