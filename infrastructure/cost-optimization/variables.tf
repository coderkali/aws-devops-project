# Phase 10: Variables for Cost Optimization

variable "project_name" {
  description = "Project name for resource naming and tagging"
  type        = string
  default     = "devops-project"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "cost_center" {
  description = "Cost center code for billing and chargeback"
  type        = string
  default     = "engineering"
}

variable "owner_email" {
  description = "Email of resource owner for notifications"
  type        = string
  default     = "your-email@example.com"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "devops-eks-cluster"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "budget_limit_usd" {
  description = "Monthly budget limit in USD"
  type        = number
  default     = 150
}

variable "budget_alert_threshold_percent" {
  description = "Percentage of budget to trigger alert (e.g., 80 for 80%)"
  type        = number
  default     = 80
}