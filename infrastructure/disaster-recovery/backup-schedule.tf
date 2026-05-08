# Phase 12: Automated Backup Snapshots and Retention

# Lambda function for manual on-demand snapshots
resource "aws_lambda_function" "create_rds_snapshot" {
  filename      = "lambda_rds_snapshot.zip"
  function_name = "${var.project_name}-create-rds-snapshot"
  role          = aws_iam_role.lambda_rds_snapshot_role.arn
  handler       = "index.handler"
  runtime       = "python3.11"
  timeout       = 60

  environment {
    variables = {
      CATALOG_DB_ID = "catalog-db"
      ORDERS_DB_ID  = "orders-db"
      PROJECT_NAME  = var.project_name
    }
  }

  tags = {
    Name    = "${var.project_name}-create-rds-snapshot"
    Project = var.project_name
  }
}

# IAM role for Lambda
resource "aws_iam_role" "lambda_rds_snapshot_role" {
  name = "${var.project_name}-lambda-rds-snapshot-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name    = "${var.project_name}-lambda-rds-snapshot-role"
    Project = var.project_name
  }
}

# Policy for Lambda to create RDS snapshots
resource "aws_iam_role_policy" "lambda_rds_snapshot_policy" {
  name = "${var.project_name}-lambda-rds-snapshot-policy"
  role = aws_iam_role.lambda_rds_snapshot_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds:CreateDBSnapshot",
          "rds:DescribeDBSnapshots",
          "rds:DescribeDBInstances",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# EventBridge rule to run snapshot Lambda daily
resource "aws_cloudwatch_event_rule" "daily_rds_snapshot" {
  name                = "${var.project_name}-daily-rds-snapshot"
  description         = "Trigger daily RDS snapshot creation"
  schedule_expression = "cron(0 2 * * ? *)"
  state               = "ENABLED"

  tags = {
    Name    = "${var.project_name}-daily-rds-snapshot"
    Project = var.project_name
  }
}

resource "aws_cloudwatch_event_target" "daily_rds_snapshot" {
  rule      = aws_cloudwatch_event_rule.daily_rds_snapshot.name
  target_id = "RDSSnapshotLambda"
  arn       = aws_lambda_function.create_rds_snapshot.arn

  input = jsonencode({
    action = "create_snapshot"
  })
}

# Permission for EventBridge to invoke Lambda
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_rds_snapshot.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_rds_snapshot.arn
}

# CloudWatch Alarm for snapshot creation
resource "aws_cloudwatch_metric_alarm" "rds_snapshot_creation" {
  alarm_name          = "${var.project_name}-rds-snapshot-creation"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "SnapshotStorageUsed"
  namespace           = "AWS/RDS"
  period              = "86400"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "Alert if RDS snapshots not being created"

  tags = {
    Name    = "${var.project_name}-snapshot-creation-alarm"
    Project = var.project_name
  }
}

output "snapshot_lambda_function_name" {
  description = "Lambda function that creates RDS snapshots"
  value       = aws_lambda_function.create_rds_snapshot.function_name
}

output "snapshot_schedule" {
  description = "Snapshot creation schedule (2 AM UTC daily)"
  value       = "cron(0 2 * * ? *)"
}
