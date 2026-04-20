data "aws_security_group" "eks_nodes" {
  filter {
    name   = "tag:aws:eks:cluster-name"
    values = ["devops-eks-cluster"]
  }
}

resource "aws_security_group" "rds" {
  name        = "devops-rds-sg"
  description = "Allow database access from EKS nodes only"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [data.aws_security_group.eks_nodes.id]
    description     = "MySQL from EKS nodes"
  }

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [data.aws_security_group.eks_nodes.id]
    description     = "PostgreSQL from EKS nodes"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "devops-rds-sg"
  }
}

resource "aws_security_group" "redis" {
  name        = "devops-redis-sg"
  description = "Allow Redis access from EKS nodes only"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [data.aws_security_group.eks_nodes.id]
    description     = "Redis from EKS nodes"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "devops-redis-sg"
  }
}