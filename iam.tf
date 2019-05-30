data "aws_iam_policy_document" "orchestrator-assume-role" {
  version = "2012-10-17"

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_efs_file_system" "src" {
  file_system_id = "${var.SrcEFS}"
}

data "aws_iam_policy_document" "orchestrator" {
  version = "2012-10-17"

  statement {
    effect    = "Allow"
    resources = ["arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/lambda/*"]

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
  }

  statement {
    effect    = "Allow"
    resources = ["arn:aws:autoscaling:${local.region}:${local.account_id}:autoscalingGroup:*:autoScalingGroupName/${aws_autoscaling_group.backup_instances.name}"]
    actions   = ["autoscaling:UpdateAutoScalingGroup"]
  }

  statement {
    effect    = "Allow"
    resources = ["*"]
    actions   = ["cloudwatch:GetMetricStatistics"] # resource level permission not allowed
  }

  statement {
    effect  = "Allow"
    actions = ["elasticfilesystem:DescribeFileSystems"]

    resources = [
      "${data.aws_efs_file_system.src.arn}",
      "${aws_efs_file_system.dst.arn}",
    ]
  }

  statement {
    effect    = "Allow"
    resources = ["arn:aws:events:${local.region}:${local.account_id}:rule/*"]

    actions = [
      "events:DeleteRule",
      "events:ListTargetsByRule",
      "events:PutRule",
      "events:PutTargets",
      "events:RemoveTargets",
    ]
  }

  statement {
    effect    = "Allow"
    resources = ["${aws_dynamodb_table.efs.arn}"]

    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
    ]
  }

  statement {
    effect    = "Allow"
    resources = ["${aws_cloudformation_stack.sns.outputs.ARN}"]
    actions   = ["sns:Publish"]
  }

  statement {
    effect = "Allow"

    resources = ["arn:aws:lambda:${local.region}:${local.account_id}:function:${var.name}-orchestrator-${random_uuid.function_name.result}"]

    actions = [
      "lambda:AddPermission",
      "lambda:GetFunction",
      "lambda:RemovePermission",
    ]
  }

  statement {
    effect  = "Allow"
    actions = ["ssm:SendCommand"]

    resources = [
      "arn:aws:ec2:${local.region}:${local.account_id}:instance/*",
      "arn:aws:ssm:*:*:document/AWS-RunShellScript",
      "${aws_s3_bucket.logs.arn}/*",
    ]
  }
}

resource "aws_iam_role" "orchestrator" {
  name_prefix        = "${var.name}-orchestrator-"
  assume_role_policy = "${data.aws_iam_policy_document.orchestrator.json}"
  path               = "/"

  tags = "${merge(
    local.tags,
    var.tags,
    map(
      "Name", "${var.name}-orchestrator-role"
    )
  )}"
}

resource "aws_iam_role_policy" "orchestrator" {
  name_prefix = "${var.name}-orchestrator-"
  policy      = "${data.aws_iam_policy_document.orchestrator.json}"
  role        = "${aws_iam_role.orchestrator.name}"
}

data "aws_iam_policy_document" "ec2-assume-role" {
  version = "2012-10-17"

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2" {
  name_prefix        = "${var.name}-ec2-"
  assume_role_policy = "${data.aws_iam_policy_document.ec2-assume-role.json}"
  path               = "/"

  tags = "${merge(
    local.tags,
    var.tags,
    map(
      "Name", "${var.name}-ec2-role"
    )
  )}"
}

data "aws_iam_policy_document" "ec2" {
  version = "2012-10-17"

  statement {
    effect = "Allow"

    resources = [
      "arn:aws:autoscaling:${local.region}:${local.account_id}:autoScalingGroup:*:autoScalingGroupName/${aws_autoscaling_group.backup_instances.name}",
      "arn:aws:autoscaling:${local.region}:${local.account_id}:autoScalingGroup:*:autoScalingGroupName/${aws_launch_configuration.backup_instance.name}",
    ]

    actions = [
      "autoscaling:CompleteLifecycleAction",
      "autoscaling:SetDesiredCapacity",
    ]
  }

  statement {
    effect    = "Allow"
    resources = ["*"]
    actions   = ["dynamodb:UpdateItem"]
  }

  statement {
    effect    = "Allow"
    resources = ["*"]
    actions   = ["cloudwatch:GetMetricStatistics"]
  }

  statement {
    effect    = "Allow"
    resources = ["${aws_s3_bucket.logs.arn}/*"]
    actions   = ["s3:PutObject"]
  }

  statement {
    effect    = "Allow"
    resources = ["*"]
    actions   = ["ec2:DescribeTags"]
  }
}

resource "aws_iam_role_policy" "ec2" {
  name_prefix = "${var.name}-ec2-"
  policy      = "${data.aws_iam_policy_document.ec2.json}"
  role        = "${aws_iam_role.ec2.name}"
}

resource "aws_iam_role_policy_attachment" "ec2" {
  role       = "${aws_iam_role.ec2.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_iam_instance_profile" "ec2" {
  name_prefix = "${var.name}-"
  path        = "/"
  role        = "${aws_iam_role.ec2.name}"
}
