
resource "aws_vpc" "vpc" {
  cidr_block           = "${var.vpc_cidr}"
  instance_tenancy     = "default"
  enable_dns_hostnames = true

  tags = "${merge(var.tags, map("Name", "${var.env_name}-vpc"))}"
}

resource "aws_security_group" "vms_security_group" {
  name        = "vms_security_group"
  description = "VMs Security Group"
  vpc_id      = "${aws_vpc.vpc.id}"

  ingress {
    cidr_blocks = ["${var.vpc_cidr}"]
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
  }

  tags = "${merge(var.tags, map("Name", "${var.env_name}-vms-security-group"))}"
}

resource "aws_security_group" "nat_security_group" {
  name        = "nat_security_group"
  description = "NAT Security Group"
  vpc_id      = "${aws_vpc.vpc.id}"

  ingress {
    cidr_blocks = ["${var.vpc_cidr}"]
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
  }

  tags = "${merge(var.tags, map("Name", "${var.env_name}-nat-security-group"))}"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = "${aws_eip.nat_eip.id}"
  subnet_id     = "${element(aws_subnet.public_subnets.*.id, 0)}"

  tags = "${merge(var.tags, map("Name", "${var.env_name}-nat"))}"

  depends_on = ["aws_internet_gateway.ig"]
}

resource "aws_eip" "nat_eip" {
  vpc = true

  tags = "${var.tags}"
}

resource "aws_security_group" "vpce_security_group" {
  name        = "vpce_security_group"
  description = "VPCE Security Group"
  vpc_id      = "${aws_vpc.vpc.id}"

  count = "${var.ops_manager_private ? 1 : 0 }"

  ingress {
    cidr_blocks = ["${var.vpc_cidr}"]
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
  }

  tags = "${merge(var.tags, map("Name", "${var.env_name}-vpce-security-group"))}"
}


resource "aws_vpc_endpoint" "ec2" {
  vpc_id            = "${aws_vpc.vpc.id}"
  service_name      = "com.amazonaws.${var.region}.ec2"
  vpc_endpoint_type = "Interface"

  subnet_ids          = ["${aws_subnet.infrastructure_subnets.*.id}"]

  security_group_ids = [
    "${aws_security_group.vpce_security_group.id}",
  ]

  count = "${var.ops_manager_private ? 1 : 0 }"

  private_dns_enabled = "${local.use_route53 ? true : false}"
}

resource "aws_vpc_endpoint" "elasticloadbalancing" {
  vpc_id            = "${aws_vpc.vpc.id}"
  service_name      = "com.amazonaws.${var.region}.elasticloadbalancing"
  vpc_endpoint_type = "Interface"

  subnet_ids          = ["${aws_subnet.infrastructure_subnets.*.id}"]

  security_group_ids = [
    "${aws_security_group.vpce_security_group.id}",
  ]

  count = "${var.ops_manager_private ? 1 : 0 }"

  private_dns_enabled = "${local.use_route53 ? true : false}"
}

# resource "aws_vpc_endpoint" "s3" {
#   vpc_id            = "${aws_vpc.vpc.id}"
#   service_name      = "com.amazonaws.${var.region}.s3"
#   vpc_endpoint_type = "Gateway"

#   subnet_ids          = ["${aws_subnet.infrastructure_subnets.*.id}"]

#   security_group_ids = [
#     "${aws_security_group.vpce_security_group.id}",
#   ]

#   count = "${var.ops_manager_private ? 1 : 0 }"

#   private_dns_enabled = "${local.use_route53 ? true : false}"
# }