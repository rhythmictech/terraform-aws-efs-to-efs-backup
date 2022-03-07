data "aws_region" "current" {
}

data "aws_caller_identity" "current" {
}

locals {
  region        = data.aws_region.current.name
  account_id    = data.aws_caller_identity.current.account_id
  instance_type = "c5.xlarge"

  validIntervals = [
    "daily",
    "weekly",
    "monthly",
  ]

  validBackupWindows = [
    60,
    90,
    120,
    150,
    180,
    240,
    300,
    360,
    480,
    600,
    720,
    840,
    960,
    1080,
    1200,
    1320,
  ]

  validEFSModes = [
    "generalPurpose",
    "maxIO",
  ]

  validAnonymousData = [
    "Yes",
    "No",
  ]

  tags = {
    tf_module = "efs-to-efs-backup"
  }
}

variable "name" {
  description = "Name for module and child resources"
  type        = string
  default     = "efs-backup"
}

variable "tags" {
  description = "Tags that should be applied to resources"
  type        = map(string)
  default     = {}
}

variable "send_anonymous_data" {
  description = "Whether to send anonymous data back to Amazon"
  type        = string
  default     = "Yes"
}

module "is_anon_data_valid" {
  source  = "rhythmictech/errorcheck/terraform"
  version = "~> 1.0.0"

  assert        = contains(local.validAnonymousData, var.send_anonymous_data)
  error_message = "'${var.send_anonymous_data}' is not a valid value for 'send_anonymous_data'. Must be one of ${local.validAnonymousData}"
}

variable "SrcEFS" {
  description = "Source EFS Id"
  type        = string
}

variable "IntervalTag" {
  description = "Interval label to identify backups"
  type        = string
  default     = "daily"
}
  
module "is_interval_valid" {
  source  = "rhythmictech/errorcheck/terraform"
  version = "~> 1.0.0"

  assert        = contains(local.validIntervals, var.IntervalTag)
  error_message = "'${var.IntervalTag}' is not a valid value for 'IntervalTag'. Must be one of ${local.validIntervals}"
}

variable "Retain" {
  description = "Backups you want to retain"
  default     = 7
  type        = number
}

variable "FolderLabel" {
  description = "Folder for your backups"
  type        = string
  default     = "efs-backup"
}

variable "BackupWindow" {
  description = "Backup Window duration in minutes"
  type        = number
  default     = 180
}
  
module "is_backup_window_valid" {
  source  = "rhythmictech/errorcheck/terraform"
  version = "~> 1.0.0"

  assert        = contains(local.validBackupWindows, var.BackupWindow)
  error_message = "'${var.BackupWindow}' is not a valid value for 'BackupWindow'. Must be one of ${local.validBackupWindows}"
}

variable "BackupSchedule" {
  description = "Schedule for running backup"
  type        = string
  default     = "cron(0 2 * * ? *)"
}

variable "BackupPrefix" {
  description = "Source prefix for backup"
  type        = string
  default     = "/"
}

variable "EFSMode" {
  description = "Performance mode for backup EFS"
  type        = string
  default     = "generalPurpose"
}
  
module "is_backup_window_valid" {
  source  = "rhythmictech/errorcheck/terraform"
  version = "~> 1.0.0"

  assert        = contains(local.validEFSModes, var.EFSMode)
  error_message = "'${var.EFSMode}' is not a valid value for 'EFSMode'. Must be one of ${local.validEFSModes}"
}

variable "SuccessNotification" {
  description = "Do you want to be notified for successful backups? *for failure, you will always be notified"
  type        = bool
  default     = true
}

variable "VpcId" {
  description = "VPC where the source EFS has mount targets"
  type        = string
}

data "aws_vpc" "is_vpc_valid" {
  id = var.VpcId
}

variable "Subnets" {
  description = "List of SubnetIDs for EC2, must be same AZ as EFS Mount Targets(Choose 2)"
  type        = list(string)
}

variable "Email" {
  description = "Email for backup notifications"
  type        = string
}

variable "Dashboard" {
  description = "Do you want a dashboard for your metrics?"
  type        = bool
  default     = true
}

variable "EFSEncryption" {
  description = "Do you want backup EFS to be encrypted?"
  type        = bool
  default     = true
}
