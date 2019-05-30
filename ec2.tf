data "aws_iam_policy_document" "ec2" {
  version = "2012-10-17"

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecw2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2" {
  name_prefix        = "${var.name}-"
  assume_role_policy = "${data.aws_iam_policy_document.ec2.json}"
  path               = "/"

  tags = "${merge(
    local.tags,
    var.tags,
    map(
      "Name", "${var.name}-ec2-role"
    )
  )}"
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

data "template_file" "userdata" {
  template = "${file("userdata.sh.tpl")}"

  vars {
    SrcEFS       = "${var.SrcEFS}"
    DstEFS       = "${aws_efs_file_system.dst.id}"
    IntervalTag  = "${var.IntervalTag}"
    Retain       = "${var.Retain}"
    FolderLabel  = "${var.FolderLabel}"
    BackupPrefix = "${var.BackupPrefix}"
  }
}

resource "aws_launch_configuration" "backup_instance" {
  name_prefix          = "${var.name}-"
  image_id             = ""
  security_groups      = ["${aws_security_group.efs.id}"]
  instance_type        = "c5.xlarge"
  iam_instance_profile = "${aws_iam_instance_profile.ec2.name}"
  user_data            = "${data.template_file.userdata.rendered}"
}

locals {
  tag_keys   = "${concat(keys(local.tags), keys(var.tags))}"
  tag_values = "${concat(values(local.tags), values(var.tags))}"
}

data "null_data_source" "asg-tags" {
  count = "${length(local.tag_keys)}"

  inputs {
    key                 = "${local.tag_keys[count.index]}"
    value               = "${local.tag_values[count.index]}"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_group" "backup_instances" {
  name_prefix          = "${var.name}-"
  max_size             = 1
  min_size             = 0
  desired_capacity     = 0
  vpc_zone_identifier  = "${var.Subnets}"
  launch_configuration = "${aws_launch_configuration.backup_instance.name}"

  tags = [
    "${data.null_data_source.asg-tags.*.outputs}",
    {
      key                 = "Name"
      value               = "${var.name}-asg"
      propagate_at_launch = true
    },
  ]
}
