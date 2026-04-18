terraform {
  backend "s3" {
    bucket         = "devops-project-tfstate-940278683030"
    key            = "vpc/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "devops-project-tfstate-lock"
    encrypt        = true
  }
}