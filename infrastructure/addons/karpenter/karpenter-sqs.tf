# Phase 6: SQS Queue for Spot Interruption Events

resource "aws_sqs_queue" "karpenter_spot_interruption" {
  name                       = "${var.cluster_name}-karpenter-spot-interruption"
  message_retention_seconds  = 300
  visibility_timeout_seconds = 120

  tags = {
    Name    = "${var.cluster_name}-karpenter-spot-interruption"
    Project = var.project_name
  }
}

resource "aws_cloudwatch_event_rule" "karpenter_spot_interruption" {
  name                = "${var.cluster_name}-karpenter-spot-interruption"
  description         = "Capture EC2 Spot instance interruption notices for Karpenter"
  event_bus_name      = "default"
  state               = "ENABLED"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Spot Instance Interruption Warning"]
  })

  tags = {
    Name    = "${var.cluster_name}-karpenter-spot-interruption"
    Project = var.project_name
  }
}

resource "aws_cloudwatch_event_target" "karpenter_spot_interruption" {
  rule      = aws_cloudwatch_event_rule.karpenter_spot_interruption.name
  target_id = "KarpenterSpotInterruptionQueue"
  arn       = aws_sqs_queue.karpenter_spot_interruption.arn
}

output "karpenter_spot_interruption_queue_url" {
  description = "URL of the SQS queue for Spot interruption events"
  value       = aws_sqs_queue.karpenter_spot_interruption.url
}

output "karpenter_spot_interruption_queue_arn" {
  description = "ARN of the SQS queue for Spot interruption events"
  value       = aws_sqs_queue.karpenter_spot_interruption.arn
}