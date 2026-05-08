# Phase 12: Variables for Disaster Recovery

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "devops-project"
}

variable "owner_email" {
  description = "Email for disaster recovery alerts"
  type        = string
  default     = "your-email@example.com"
}

variable "backup_target_region" {
  description = "AWS region for backup replication (disaster recovery)"
  type        = string
  default     = "us-west-2"
}

variable "backup_retention_days" {
  description = "Number of days to retain RDS backups"
  type        = number
  default     = 30
}

variable "backup_window" {
  description = "Preferred backup time window (UTC)"
  type        = string
  default     = "03:00-04:00"
}

variable "enable_cross_region_backup" {
  description = "Enable cross-region backup replication"
  type        = bool
  default     = true
}

variable "enable_automated_snapshots" {
  description = "Enable automated daily snapshots"
  type        = bool
  default     = true
}

variable "snapshot_schedule" {
  description = "Cron expression for snapshot schedule (default: 2 AM UTC daily)"
  type        = string
  default     = "cron(0 2 * * ? *)"
}
