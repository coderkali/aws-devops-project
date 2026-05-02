# Phase 10: Resource Tagging Strategy for Cost Allocation

# Tags applied to all resources
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    CostCenter  = var.cost_center
    Owner       = var.owner_email
    CreatedAt   = timestamp()
  }
}

# Tag EC2 instances for cost tracking
resource "aws_ec2_tag" "eks_nodes" {
  for_each = toset(data.aws_instances.eks_nodes.instance_ids)

  resource_id = each.value
  key         = "Service"
  value       = "EKS-Worker"
}

resource "aws_ec2_tag" "eks_nodes_cost_center" {
  for_each = toset(data.aws_instances.eks_nodes.instance_ids)

  resource_id = each.value
  key         = "CostCenter"
  value       = var.cost_center
}

# Data source to find EKS nodes
data "aws_instances" "eks_nodes" {
  filter {
    name   = "tag:aws:eks:cluster-name"
    values = [var.cluster_name]
  }
}

# Tag RDS instances
resource "aws_db_instance_tags" "catalog_db_tags" {
  resource_id = "arn:aws:rds:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:db:catalog-db"

  tags = merge(
    local.common_tags,
    {
      Service = "Catalog-Database"
      Type    = "MySQL"
    }
  )

  depends_on = [data.aws_db_instance.catalog_db]
}

resource "aws_db_instance_tags" "orders_db_tags" {
  resource_id = "arn:aws:rds:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:db:orders-db"

  tags = merge(
    local.common_tags,
    {
      Service = "Orders-Database"
      Type    = "PostgreSQL"
    }
  )

  depends_on = [data.aws_db_instance.orders_db]
}

# Tag ElastiCache clusters
resource "aws_elasticache_tags" "redis_tags" {
  resource_id = "arn:aws:elasticache:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster:cache-cluster-1"

  tags = merge(
    local.common_tags,
    {
      Service = "Redis-Cache"
    }
  )

  depends_on = [data.aws_elasticache_cluster.redis]
}

# Data sources to get resource ARNs
data "aws_db_instance" "catalog_db" {
  db_instance_identifier = "catalog-db"
}

data "aws_db_instance" "orders_db" {
  db_instance_identifier = "orders-db"
}

data "aws_elasticache_cluster" "redis" {
  cluster_id = "cache-cluster-1"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Cost allocation tags output
output "tagging_strategy" {
  description = "Tagging strategy applied to all resources"
  value = {
    common_tags = local.common_tags
    services = {
      "EKS-Nodes"        = "Kubernetes worker nodes"
      "Catalog-Database" = "MySQL database for catalog service"
      "Orders-Database"  = "PostgreSQL database for orders service"
      "Redis-Cache"      = "ElastiCache for caching"
    }
  }
}

output "cost_center" {
  description = "Cost center for billing"
  value       = var.cost_center
}