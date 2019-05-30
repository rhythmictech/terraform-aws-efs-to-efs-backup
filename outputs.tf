output "UUID" {
  description = "Anonymous UUID for each stack deployment"
  value       = "${local.global_uuid}"
}

output "SNSTopic" {
  description = "Topic for your backup notifications"
  value       = "${aws_cloudformation_stack.sns.outputs.ARN}"
}

output "BackupEFS" {
  description = "Backup EFS created by template"
  value       = "${aws_efs_file_system.dst.id}"
}

output "DashboardView" {
  description = "CloudWatch Dashboard to view EFS metrics"
  value = "${join("", aws_cloudwatch_dashboard.dash.*.dashboard_name)}"
}

output "LogBucket" {
  description = "S3 bucket for your backup logs"
  value       = "value"
}

output "AmiId" {
  description = "AMI ID vended in template"
  value       = "${data.aws_ami.efs_backup.id}"
}

# Passive outputs
output "SourceEFS" {
  description = "Source EFS provided by user"
  value       = "${var.SrcEFS}"
}
