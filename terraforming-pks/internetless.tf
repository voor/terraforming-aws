module "jumpbox" {
  source = "../modules/jumpbox"

  vpc_id             = "${module.infra.vpc_id}"
  env_name           = "${var.env_name}"
  dns_suffix         = "${var.dns_suffix}"
  public_subnet_ids  = "${module.infra.public_subnet_ids}"
  availability_zones = "${var.availability_zones}"
  tags               = "${local.actual_tags}"
  use_route53        = "${var.use_route53}"
  zone_id            = "${module.infra.zone_id}"

  jumpbox_ami_id = "${data.aws_ami.ubuntu_ami.id}"
}

variable "proxy_ca_cert" {}

variable "proxy_ca_private_key" {}

variable "ubuntu_owner_id" {
  default = "099720109477"
}

variable "ubuntu_ami_name" {
  default = "ubuntu/images/hvm-ssd/ubuntu-bionic-*-amd64-server-*"
}

data "aws_ami" "ubuntu_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["${var.ubuntu_ami_name}"]
  }

  owners = ["${var.ubuntu_owner_id}"] # Canonical
}

module "squid" {
  source = "../modules/squid"

  ssl_ca_cert        = "${var.proxy_ca_cert}"
  ssl_ca_private_key = "${var.proxy_ca_private_key}"

  vpc_id                          = "${module.infra.vpc_id}"
  proxy_subnets_id                = "${module.infra.public_subnet_ids}"
  squid_access_security_group_ids = ["${module.jumpbox.jumpbox_security_group_id}"]

  availability_zones = "${var.availability_zones}"
  env_name           = "${var.env_name}"
  pcf_vpc_cidr       = "${var.vpc_cidr}"
  tags               = "${local.actual_tags}"

  squid_ami_id = "${data.aws_ami.ubuntu_ami.id}"
}