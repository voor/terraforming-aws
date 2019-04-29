resource "aws_directory_service_directory" "directory" {
  name     = "${local.directory_name}"
  password = "${var.directory_password}"
  size     = "Small"

  vpc_settings {
    subnet_ids = ["${var.public_subnet_ids}"]
  }

  tags = "${merge(var.tags, map("Name", "${var.env_name}-directory"))}"
}

locals {
  directory_name = "${var.directory_name != "" ? var.directory_name : "corp.${var.env_name}.${var.dns_suffix}" }"
}
