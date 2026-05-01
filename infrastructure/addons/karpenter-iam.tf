# Phase 6: Karpenter IAM Role for Service Account (IRSA)

locals {
  karpenter_namespace = "karpenter"
  karpenter_sa_name   = "karpenter"
}

data "aws_iam_policy_document" "karpenter_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:${local.karpenter_namespace}:${local.karpenter_sa_name}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "karpenter" {
  name               = "${var.cluster_name}-karpenter-controller"
  assume_role_policy = data.aws_iam_policy_document.karpenter_assume_role.json

  tags = {
    Name    = "${var.cluster_name}-karpenter-controller"
    Project = var.project_name
  }
}

data "aws_iam_policy_document" "karpenter_controller" {
  statement {
    sid    = "AllowEC2"
    effect = "Allow"
    actions = [
      "ec2:CreateFleet",
      "ec2:CreateLaunchTemplate",
      "ec2:CreateTags",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeImages",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceTypeOfferings",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeLaunchTemplates",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSpotPriceHistory",
      "ec2:DescribeSubnets",
      "ec2:DescribeTags",
      "ec2:DescribeVpcs",
      "ec2:GetInstanceTypesFromInstanceRequirements",
      "ec2:RunInstances",
      "ec2:TerminateInstances",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AllowSSM"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
    ]
    resources = ["arn:aws:ssm:${data.aws_region.current.name}::parameter/aws/service/eks/optimized-ami/*"]
  }

  statement {
    sid    = "AllowPricingAndEC2"
    effect = "Allow"
    actions = [
      "pricing:GetSpotPriceHistory",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AllowSQS"
    effect = "Allow"
    actions = [
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:ReceiveMessage",
    ]
    resources = [aws_sqs_queue.karpenter_spot_interruption.arn]
  }

  statement {
    sid    = "AllowPassRole"
    effect = "Allow"
    actions = [
      "iam:PassRole",
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/*karpenter*",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/*-NodeInstanceRole-*",
    ]
  }
}

resource "aws_iam_role_policy" "karpenter_controller" {
  name   = "${var.cluster_name}-karpenter-controller"
  role   = aws_iam_role.karpenter.name
  policy = data.aws_iam_policy_document.karpenter_controller.json
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

output "karpenter_role_arn" {
  description = "ARN of Karpenter controller IAM role"
  value       = aws_iam_role.karpenter.arn
}

output "karpenter_namespace" {
  description = "Kubernetes namespace for Karpenter"
  value       = local.karpenter_namespace
}

output "karpenter_sa_name" {
  description = "Kubernetes service account name for Karpenter"
  value       = local.karpenter_sa_name
}