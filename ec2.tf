data "template_file" "userdata" {
  template = file("${path.module}/userdata.sh.tpl")

  vars = {
    SrcEFS       = var.SrcEFS
    DstEFS       = aws_efs_file_system.dst.id
    IntervalTag  = var.IntervalTag
    Retain       = var.Retain
    FolderLabel  = var.FolderLabel
    BackupPrefix = var.BackupPrefix
  }
}

resource "aws_launch_configuration" "backup_instance" {
  name_prefix          = "${var.name}-"
  image_id             = data.aws_ami.efs_backup.id
  security_groups      = [aws_security_group.efs.id]
  instance_type        = local.instance_type
  iam_instance_profile = aws_iam_instance_profile.ec2.name
  user_data            = data.template_file.userdata.rendered

  lifecycle {
    create_before_destroy = true
  }
}

locals {
  tag_keys   = concat(keys(local.tags), keys(var.tags))
  tag_values = concat(values(local.tags), values(var.tags))
}

data "null_data_source" "asg-tags" {
  count = length(local.tag_keys)

  inputs = {
    key                 = local.tag_keys[count.index]
    value               = local.tag_values[count.index]
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_group" "backup_instances" {
  name_prefix          = "${var.name}-"
  max_size             = 1
  min_size             = 0
  desired_capacity     = 0
  vpc_zone_identifier  = var.Subnets
  launch_configuration = aws_launch_configuration.backup_instance.name

  tags = [
    data.null_data_source.asg-tags.*.outputs,
    {
      key                 = "Name"
      value               = "${var.name}-asg"
      propagate_at_launch = true
    },
  ]
}

resource "random_uuid" "lifecycle_hook_name" {
}

resource "aws_autoscaling_lifecycle_hook" "backup_instances" {
  name                   = "${var.name}-${random_uuid.lifecycle_hook_name.result}"
  autoscaling_group_name = aws_autoscaling_group.backup_instances.name
  heartbeat_timeout      = 3600
  lifecycle_transition   = "autoscaling:EC2_INSTANCE_TERMINATING"
}

