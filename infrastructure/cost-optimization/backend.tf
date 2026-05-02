# Phase 10: Remote Backend Configuration for Cost Optimization Module

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "devops-project-tfstate-940278683030"
    key            = "cost-optimization/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "devops-project-tfstate-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      Module      = "cost-optimization"
      ManagedBy   = "Terraform"
    }
  }
}