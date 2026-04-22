# Phase 6: Karpenter Helm Chart Installation

resource "helm_repository" "karpenter" {
  name   = "karpenter"
  url    = "oci://public.ecr.aws/karpenter"
  type   = "oci"
}

resource "helm_release" "karpenter" {
  namespace        = "karpenter"
  create_namespace = true

  name       = "karpenter"
  repository = "karpenter"
  chart      = "karpenter"
  version    = "1.1.0"

  values = [
    yamlencode({
      serviceAccount = {
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.karpenter.arn
        }
      }
      settings = {
        aws = {
          clusterName        = var.cluster_name
          interruptionQueue  = aws_sqs_queue.karpenter_spot_interruption.name
          vmMemoryOverheadPercent = 5
        }
        batchMaxDuration   = "10s"
        batchIdleDuration  = "1s"
      }
      logLevel = "debug"
      replicas = 2
    })
  ]

  depends_on = [
    aws_iam_role.karpenter,
    aws_sqs_queue.karpenter_spot_interruption,
    aws_cloudwatch_event_rule.karpenter_spot_interruption,
    aws_cloudwatch_event_target.karpenter_spot_interruption,
  ]

  wait = true

  timeout = 600

  lifecycle {
    ignore_changes = [
      values
    ]
  }
}

resource "kubernetes_manifest" "karpenter_ec2_node_class" {
  manifest = {
    apiVersion = "karpenter.k8s.aws/v1"
    kind       = "EC2NodeClass"
    metadata = {
      name      = "default"
      namespace = "karpenter"
    }
    spec = {
      ami = {
        owner = "amazon"
        name  = "amazon-eks-node-1.31-*"
      }
      subnet = {
        tags = {
          "karpenter.sh/discovery" = var.cluster_name
        }
      }
      security_groups = {
        tags = {
          "karpenter.sh/discovery" = var.cluster_name
        }
      }
      iam_instance_profile = "karpenter-for-${var.cluster_name}"
      block_device_mappings = [
        {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 100
            volume_type           = "gp3"
            delete_on_termination = true
            encrypted             = true
          }
        }
      ]
      tags = {
        NodeType    = "karpenter-managed"
        Environment = var.project_name
        ManagedBy   = "karpenter"
      }
      metadata_options = {
        http_endpoint               = "enabled"
        http_protocol_ipv6          = "disabled"
        http_put_response_hop_limit = 2
        http_tokens                 = "required"
      }
    }
  }

  depends_on = [helm_release.karpenter]
}

resource "kubernetes_manifest" "karpenter_node_pool" {
  manifest = {
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"
    metadata = {
      name      = "default"
      namespace = "karpenter"
    }
    spec = {
      template = {
        spec = {
          requirements = [
            {
              key      = "karpenter.k8s.aws/instance-family"
              operator = "In"
              values   = ["m5", "m6i", "t3"]
            },
            {
              key      = "karpenter.k8s.aws/instance-size"
              operator = "In"
              values   = ["medium", "large", "xlarge", "2xlarge"]
            },
            {
              key      = "karpenter.sh/capacity-type"
              operator = "In"
              values   = ["on-demand", "spot"]
            },
            {
              key      = "kubernetes.io/arch"
              operator = "In"
              values   = ["amd64"]
            },
            {
              key      = "topology.kubernetes.io/zone"
              operator = "In"
              values   = ["us-east-1a", "us-east-1b"]
            }
          ]
          node_class_ref = {
            name = "default"
          }
        }
      }
      limits = {
        cpu    = "100"
        memory = "200Gi"
      }
      disruption = {
        consolidate_after = "30s"
        consolidate_on_ttl = true
        expire_after       = "604800s"
        budgets = [
          {
            nodes = "10%"
          }
        ]
      }
      weight = 100
    }
  }

  depends_on = [kubernetes_manifest.karpenter_ec2_node_class]
}

output "karpenter_namespace" {
  description = "Kubernetes namespace where Karpenter is installed"
  value       = helm_release.karpenter.namespace
}

output "karpenter_release_status" {
  description = "Helm release status"
  value       = helm_release.karpenter.status
}