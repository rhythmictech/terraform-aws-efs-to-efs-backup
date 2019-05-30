data "template_file" "dashboard_body" {
  template = "${file("${path.module}/dashboard.json.tpl")}"

  vars {
    ScrEFS        = "${var.SrcEFS}"
    DstEFS        = "${aws_efs_file_system.dst.id}"
    AWS_Region    = "${local.region}"
    AWS_StackName = "${var.name}"
    Orchestrator  = "${aws_lambda_function.orchestrator.function_name}"
    EFSDynamoDB   = "${aws_dynamodb_table.efs.name}"
  }
}

resource "aws_cloudwatch_dashboard" "dash" {
  count          = "${var.Dashboard}"
  dashboard_name = "${var.name}-${local.region}-${local.global_uuid}"
  dashboard_body = "${data.template_file.dashboard_body.rendered}"
}

data "template_file" "cloudformation_sns_stack" {
  template = "${file("${path.module}/sns.cfn.json.tpl")}"

  vars {
    email_address = "${var.Email}"
  }
}

resource "aws_cloudformation_stack" "sns" {
  # Using cloudformation because Terraform can't natively create an SNS email subscription
  name = "${var.name}-sns-cfn-stack-${local.global_uuid}"
  template_body = "${data.template_file.cloudformation_sns_stack.rendered}"

  tags = "${merge(
    local.tags,
    var.tags,
    map(
      "Name", "${var.name}-sns-cfn"
    )
  )}"
}
