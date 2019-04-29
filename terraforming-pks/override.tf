module "jumpbox" {
  source = "../modules/jumpbox"

  vpc_id             = "${module.infra.vpc_id}"
  env_name           = "${var.env_name}"
  public_subnet_ids  = "${module.infra.public_subnet_ids}"
  availability_zones = "${var.availability_zones}"
  tags               = "${local.actual_tags}"
  use_route53        = "${var.use_route53}"
  zone_id            = "${module.infra.zone_id}"
}

module "directory" {}

variable "proxy_ca_cert" {}

variable "proxy_ca_private_key" {}

module "squid" {
  ssl_ca_cert                     = "${var.proxy_ca_cert}"
  availability_zones              = "${var.availability_zones}"
  env_name                        = "${var.env_name}"
  ssl_ca_private_key              = "${var.proxy_ca_private_key}"
  proxy_subnets_id                = "${module.infra.public_subnet_ids}"
  squid_access_security_group_ids = "${module.jumpbox.jumpbox_security_group_id}"
}
