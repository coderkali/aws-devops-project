# Phase 10: CloudWatch Dashboard for Cost Monitoring

resource "aws_cloudwatch_dashboard" "cost_optimization" {
  dashboard_name = "${var.project_name}-cost-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Billing", "EstimatedCharges", { stat = "Maximum" }]
          ]
          period = 86400
          stat   = "Maximum"
          region = var.region
          title  = "Estimated Monthly Charges"
          yAxis = {
            left = {
              min = 0
            }
          }
        }
      },
      {
        type = "log"
        properties = {
          query   = "fields @timestamp, @message | stats count() by bin(5m)"
          region  = var.region
          title   = "Cost Anomalies"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", { stat = "Average" }],
            [".", "NetworkIn", { stat = "Sum" }],
            [".", "NetworkOut", { stat = "Sum" }]
          ]
          period = 3600
          stat   = "Average"
          region = var.region
          title  = "EC2 Resource Utilization"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", { stat = "Average" }],
            [".", "DatabaseConnections", { stat = "Sum" }]
          ]
          period = 3600
          stat   = "Average"
          region = var.region
          title  = "RDS Performance"
        }
      }
    ]
  })
}

# SNS Topic for cost notifications
resource "aws_sns_topic" "cost_alerts" {
  name = "${var.project_name}-cost-alerts"

  tags = {
    Name    = "${var.project_name}-cost-alerts"
    Project = var.project_name
  }
}

resource "aws_sns_topic_subscription" "cost_alerts_email" {
  topic_arn = aws_sns_topic.cost_alerts.arn
  protocol  = "email"
  endpoint  = var.owner_email
}

# CloudWatch Alarm for high costs
resource "aws_cloudwatch_metric_alarm" "high_costs" {
  alarm_name          = "${var.project_name}-high-costs"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = "86400"
  statistic           = "Maximum"
  threshold           = var.budget_limit_usd * 0.9  # 90% of budget
  alarm_description   = "Alert when costs exceed 90% of monthly budget"
  alarm_actions       = [aws_sns_topic.cost_alerts.arn]

  tags = {
    Name    = "${var.project_name}-high-costs-alarm"
    Project = var.project_name
  }
}

output "cost_dashboard_url" {
  description = "URL to CloudWatch cost dashboard"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${var.region}#dashboards:name=${aws_cloudwatch_dashboard.cost_optimization.dashboard_name}"
}

output "cost_alerts_topic_arn" {
  description = "SNS topic ARN for cost alerts"
  value       = aws_sns_topic.cost_alerts.arn
}