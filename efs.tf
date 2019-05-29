resource "aws_security_group" "efs" {
  name_prefix = "${var.name}-"
  description = "SG for EFS backup solution ${var.name}"
  vpc_id      = "${var.VpcId}"

  ingress {
    from_port = "-1"
    to_port   = "-1"
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${merge(
    local.tags,
    var.tags,
    map(
      "Name", "${var.name}-sg"
    )
  )}"
}

resource "aws_efs_file_system" "dst" {
  encrypted        = "${var.EFSEncryption}"
  performance_mode = "${var.EFSMode}"

  tags = "${merge(
    local.tags,
    var.tags,
    map(
      "Name", "${var.name}-dst-fs"
    )
  )}"
}

resource "aws_efs_mount_target" "dst" {
  count           = "${length(var.Subnets)}"
  file_system_id  = "${aws_efs_file_system.dst.id}"
  subnet_id       = "${var.Subnets[count.index]}"
  security_groups = ["${aws_security_group.efs.id}"]
}
