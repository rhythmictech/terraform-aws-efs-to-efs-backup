resource "random_uuid" "function_name" {}

resource "aws_lambda_function" "orchestrator" {
  function_name = "${var.name}-orchestrator-${random_uuid.function_name.result}"
  description   = "EFS Backup - Lambda function to create EFS backups"
  handler       = "orchestrator.lambda_handler"
  role          = "${aws_iam_role.orchestrator.arn}"
  s3_bucket     = "solutions-${local.region}"
  s3_key        = "efs-backup/v1.3.1/efs_to_efs_backup.zip"
  runtime       = "python2.7"
  timeout       = 300

  environment {
    variables = {
      instance_type           = "${local.instance_type}"
      autoscaling_group_name  = "${aws_autoscaling_group.backup_instances.name}"
      source_efs              = "${var.SrcEFS}"
      destination_efs         = "${aws_efs_file_system.dst.id}"
      backup_prefix           = "${var.BackupPrefix}"
      folder_label            = "${var.FolderLabel}"
      table_name              = "${aws_dynamodb_table.efs.name}"
      backup_window_period    = "${var.BackupWindow}"
      backup_retention_copies = "${var.Retain}"
      interval_tag            = "${var.IntervalTag}"
      s3_bucket               = "${aws_s3_bucket.logs.id}"
      topic_arn               = "${aws_cloudformation_stack.sns.outputs["ARN"]}"
      uuid                    = "${local.global_uuid}"
      send_anonymous_data     = "${var.send_anonymous_data}"
      notification_on_success = "${var.SuccessNotification}"
      cw_dashboard            = "${var.Dashboard}"
      efs_mode                = "${var.EFSMode}"
    }
  }

  tags = "${merge(
    local.tags,
    var.tags,
    map(
      "Name", "${var.name}-orchestrator"
    )
  )}"
}

resource "random_uuid" "table_name" {}

resource "aws_dynamodb_table" "efs" {
  name         = "${var.name}-${random_uuid.table_name.result}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "BackupId"

  attribute = [
    {
      name = "BackupId"
      type = "S"
    },
  ]

  server_side_encryption {
    enabled = true
  }

  ttl {
    enabled        = true
    attribute_name = "ExpireItem"
  }
}

resource "aws_s3_bucket" "logs" {
  bucket_prefix = "${var.name}-logs-"

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }
}
