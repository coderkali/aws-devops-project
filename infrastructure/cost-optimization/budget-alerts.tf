# Phase 10: AWS Budget Alerts for Cost Monitoring

resource "aws_budgets_budget" "devops_project_monthly" {
  name              = "${var.project_name}-monthly-budget"
  budget_type       = "MONTHLY"
  limit_unit        = "USD"
  limit_amount      = "150"
  time_period_start = "2026-05-01"
  time_period_end   = "2099-12-31"

  tags = {
    Name    = "${var.project_name}-monthly-budget"
    Project = var.project_name
  }
}

resource "aws_budgets_budget_action" "devops_project_alert" {
  budget_name        = aws_budgets_budget.devops_project_monthly.name
  action_id          = "${var.project_name}-alert-80-percent"
  action_threshold   = 80
  action_type        = "ALERT"
  approval_model     = "AUTOMATIC"
  notification_type  = "FORECASTED"
  subscriber_type    = "EMAIL"
  subscriber_address = "your-email@example.com"

  execution_role_arn = aws_iam_role.budget_alert_role.arn
}

resource "aws_budgets_budget_action" "devops_project_alert_100" {
  budget_name        = aws_budgets_budget.devops_project_monthly.name
  action_id          = "${var.project_name}-alert-100-percent"
  action_threshold   = 100
  action_type        = "ALERT"
  approval_model     = "AUTOMATIC"
  notification_type  = "ACTUAL"
  subscriber_type    = "EMAIL"
  subscriber_address = "your-email@example.com"

  execution_role_arn = aws_iam_role.budget_alert_role.arn
}

# IAM role for budget alerts
resource "aws_iam_role" "budget_alert_role" {
  name = "${var.project_name}-budget-alert-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "budgets.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name    = "${var.project_name}-budget-alert-role"
    Project = var.project_name
  }
}

resource "aws_iam_role_policy" "budget_alert_policy" {
  name = "${var.project_name}-budget-alert-policy"
  role = aws_iam_role.budget_alert_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = "*"
      }
    ]
  })
}

output "budget_name" {
  description = "Name of the monthly budget"
  value       = aws_budgets_budget.devops_project_monthly.name
}

output "budget_limit" {
  description = "Monthly budget limit in USD"
  value       = aws_budgets_budget.devops_project_monthly.limit_amount
}