resource "aws_cloudwatch_event_rule" "BackupStartEvent" {
  name_prefix         = "${var.name}-backup-start-"
  description         = "Schedule to run EFS backup"
  schedule_expression = "${var.BackupSchedule}"
  is_enabled          = true

  tags = "${merge(
    local.tags,
    var.tags,
    map(
      "Name", "${var.name}-backup-start-event"
    )
  )}"
}

resource "random_uuid" "backup-start-event-target" {}

resource "aws_cloudwatch_event_target" "orchestrator-backup-start" {
  rule      = "${aws_cloudwatch_event_rule.BackupStartEvent.name}"
  arn       = "${aws_lambda_function.orchestrator.arn}"
  target_id = "${var.name}-orch-${random_uuid.backup-start-event-target.result}"

  input = "${jsonencode(
    map(
      "mode",
      "backup",
      "action",
      "start"
    )
  )}"
}

resource "aws_lambda_permission" "BackupStartEvent" {
  function_name       = "${aws_lambda_function.orchestrator.function_name}"
  action              = "lambda:InvokeFunction"
  principal           = "events.amazonaws.com"
  source_arn          = "${aws_cloudwatch_event_rule.BackupStartEvent.arn}"
  statement_id_prefix = "${var.name}-backup-start-event-"
}

resource "aws_cloudwatch_event_rule" "asg" {
  name_prefix = "${var.name}-asg-"
  description = "Rule to catch ASG Events"
  is_enabled  = true

  event_pattern = <<PATTERN
{
  "source": ["aws.autoscaling"],
  "detail-type": [
    "EC2 Instance-terminate Lifecycle Action",
    "EC2 Instance Terminate Successful"
  ],
  "detail": {
    "AutoScalingGroupName": ["${aws_autoscaling_group.backup_instances.name}"]
  }
}
PATTERN

  tags = "${merge(
    local.tags,
    var.tags,
    map(
      "Name", "${var.name}-backup-start-event"
    )
  )}"
}

resource "random_uuid" "asg-event-target" {}

resource "aws_cloudwatch_event_target" "asg" {
  rule      = "${aws_cloudwatch_event_rule.asg.name}"
  arn       = "${aws_lambda_function.orchestrator.arn}"
  target_id = "${var.name}-orch-${random_uuid.asg-event-target.result}"
}

resource "aws_lambda_permission" "asgEvent" {
  function_name       = "${aws_lambda_function.orchestrator.function_name}"
  action              = "lambda:InvokeFunction"
  principal           = "events.amazonaws.com"
  source_arn          = "${aws_cloudwatch_event_rule.asg.arn}"
  statement_id_prefix = "${var.name}-asg-event-"
}
