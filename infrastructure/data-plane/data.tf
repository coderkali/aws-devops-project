data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "devops-project-tfstate-940278683030"
    key    = "vpc/terraform.tfstate"
    region = "us-east-1"
  }
}

data "aws_secretsmanager_secret" "db_credentials" {
  name = "devops-project/db-credentials"
}

data "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = data.aws_secretsmanager_secret.db_credentials.id
}