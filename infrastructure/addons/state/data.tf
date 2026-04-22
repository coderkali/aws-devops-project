data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "devops-project-tfstate-940278683030"
    key    = "vpc/terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket = "devops-project-tfstate-940278683030"
    key    = "eks/terraform.tfstate"
    region = "us-east-1"
  }
}