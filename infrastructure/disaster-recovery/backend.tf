# Phase 12: Remote Backend Configuration for Disaster Recovery Module

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "devops-project-tfstate-940278683030"
    key            = "disaster-recovery/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "devops-project-tfstate-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = var.project_name
      Module      = "disaster-recovery"
      ManagedBy   = "Terraform"
    }
  }
}
