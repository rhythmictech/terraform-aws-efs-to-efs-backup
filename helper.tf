data "aws_ami" "efs_backup" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["${"amzn-ami-hvm*x86_64-gp2"}"]
  }
}

resource "random_uuid" "global" {}

locals {
  global_uuid = "${random_uuid.global.result}"
}
