data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  region        = "${data.aws_region.current.name}"
  account_id    = "${data.aws_caller_identity.current.account_id}"
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
  type        = "string"
  default     = "efs-backup"
}

variable "tags" {
  description = "Tags that should be applied to resources"
  type        = "map"
  default     = {}
}

variable "send_anonymous_data" {
  description = "Whether to send anonymous data back to Amazon"
  type        = "string"
  default     = "Yes"
}

resource "null_resource" "is_anon_data_valid" {
  count = "${contains(local.validAnonymousData, var.send_anonymous_data)? 0 : 1}"

  "\nERROR: send_anonymous_data invalid\n  Valid values are: [\n    ${join(",\n    ", local.validAnonymousData)}\n  ]\n  got: ${var.send_anonymous_data}" = true
}

variable "SrcEFS" {
  description = "Source EFS Id"
  type        = "string"
}

variable "IntervalTag" {
  description = "Interval label to identify backups"
  type        = "string"
  default     = "daily"
}

resource "null_resource" "is_interval_valid" {
  count = "${contains(local.validIntervals, var.IntervalTag)? 0 : 1}"

  "\nERROR: IntervalTag invalid\n  Valid values are: [\n    ${join(",\n    ", local.validIntervals)}\n  ]\n  got: ${var.IntervalTag}" = true
}

variable "Retain" {
  description = "Backups you want to retain"
  type        = "string"
  default     = 7
}

resource "null_resource" "is_retain_number" {
  count = "${replace(replace(var.Retain, "/^[0-9]*$/", "0"), "/^[^0-9]*$/", "1")}"

  "\nERROR: Retain must be a number\n  got: '${var.Retain}'" = true
}

variable "FolderLabel" {
  description = "Folder for your backups"
  type        = "string"
  default     = "efs-backup"
}

variable "BackupWindow" {
  description = "Backup Window duration in minutes"
  type        = "string"
  default     = 180
}

resource "null_resource" "is_backup_window_valid" {
  count = "${contains(local.validBackupWindows, var.BackupWindow)? 0 : 1}"

  "\nERROR: BackupWindow invalid\n  Valid values are: [\n    ${join(",\n    ", local.validBackupWindows)}\n  ]\n  got: ${var.BackupWindow}" = true
}

variable "BackupSchedule" {
  description = "Schedule for running backup"
  type        = "string"
  default     = "cron(0 2 * * ? *)"
}

variable "BackupPrefix" {
  description = "Source prefix for backup"
  type        = "string"
  default     = "/"
}

variable "EFSMode" {
  description = "Performance mode for backup EFS"
  type        = "string"
  default     = "generalPurpose"
}

resource "null_resource" "is_EFS_mode_valid" {
  count = "${contains(local.validEFSModes, var.EFSMode)? 0 : 1}"

  "\nERROR: EFSMode invalid\n  Valid values are: [\n    ${join(",\n    ", local.validEFSModes)}\n  ]\n  got: ${var.EFSMode}" = true
}

variable "SuccessNotification" {
  description = "Do you want to be notified for successful backups? *for failure, you will always be notified"
  type        = "string"
  default     = true
}

variable "VpcId" {
  description = "VPC where the source EFS has mount targets"
  type        = "string"
}

data "aws_vpc" "is_vpc_valid" {
  id = "${var.VpcId}"
}

variable "Subnets" {
  description = "List of SubnetIDs for EC2, must be same AZ as EFS Mount Targets(Choose 2)"
  type        = "list"
}

variable "Email" {
  description = "Email for backup notifications"
  type        = "string"
}

variable "Dashboard" {
  description = "Do you want a dashboard for your metrics?"
  type        = "string"
  default     = true
}

variable "EFSEncryption" {
  description = "Do you want backup EFS to be encrypted?"
  type        = "string"
  default     = true
}
