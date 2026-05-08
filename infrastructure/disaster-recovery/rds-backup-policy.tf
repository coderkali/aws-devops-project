# Phase 12: RDS Backup and Disaster Recovery Policies

# KMS key for database encryption
resource "aws_kms_key" "rds_key" {
  description             = "KMS key for RDS database encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name    = "${var.project_name}-rds-key"
    Project = var.project_name
  }
}

resource "aws_kms_alias" "rds_key_alias" {
  name          = "alias/${var.project_name}-rds"
  target_key_id = aws_kms_key.rds_key.key_id
}

# IAM role for RDS monitoring
resource "aws_iam_role" "rds_monitoring" {
  name = "${var.project_name}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name    = "${var.project_name}-rds-monitoring-role"
    Project = var.project_name
  }
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# SNS topic for disaster recovery alerts
resource "aws_sns_topic" "disaster_recovery_alerts" {
  name = "${var.project_name}-disaster-recovery-alerts"

  tags = {
    Name    = "${var.project_name}-disaster-recovery-alerts"
    Project = var.project_name
  }
}

resource "aws_sns_topic_subscription" "disaster_recovery_alerts_email" {
  topic_arn = aws_sns_topic.disaster_recovery_alerts.arn
  protocol  = "email"
  endpoint  = var.owner_email
}

# CloudWatch Alarm for backup failures
resource "aws_cloudwatch_metric_alarm" "rds_backup_failed" {
  alarm_name          = "${var.project_name}-rds-backup-failed"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "FailedBackupCount"
  namespace           = "AWS/RDS"
  period              = "3600"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alert when RDS backup fails"
  alarm_actions       = [aws_sns_topic.disaster_recovery_alerts.arn]

  tags = {
    Name    = "${var.project_name}-rds-backup-alarm"
    Project = var.project_name
  }
}

output "rds_backup_retention_days" {
  description = "Number of days RDS backups are retained"
  value       = 30
}

output "rds_encryption_key_arn" {
  description = "ARN of KMS key used for RDS encryption"
  value       = aws_kms_key.rds_key.arn
}

output "disaster_recovery_topic_arn" {
  description = "SNS topic for disaster recovery alerts"
  value       = aws_sns_topic.disaster_recovery_alerts.arn
}
