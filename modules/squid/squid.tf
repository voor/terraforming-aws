resource "aws_instance" "squid_proxy" {
  count         = "${length(var.availability_zones)}"
  ami           = "${var.squid_ami_id}"
  instance_type = "t2.micro"
  key_name      = "${aws_key_pair.squid_proxy.key_name}"

  network_interface {
    network_interface_id = "${element(aws_network_interface.proxy_interface.*.id, count.index)}"
    device_index         = 0
  }

  user_data = "${data.template_file.squid_payload.rendered}"

  root_block_device {
    volume_type = "gp2"
    volume_size = 150
  }

  tags = "${merge(var.tags, map("Name", "${var.env_name}-squid-proxy-${element(var.availability_zones, count.index)}"))}"
}

resource "aws_key_pair" "squid_proxy" {
  key_name   = "${var.env_name}-squid-proxy-key"
  public_key = "${tls_private_key.squid_proxy_key.public_key_openssh}"
}

resource "tls_private_key" "squid_proxy_key" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

data "template_file" "squid_payload" {
  template = "${file("${path.module}/templates/squid_proxy.tpl")}"

  vars = {
    squid_docker_image = "${var.squid_docker_image}"
    ssl_ca_cert        = "${var.ssl_ca_cert}"
    ssl_ca_private_key = "${var.ssl_ca_private_key}"
  }
}

resource "aws_network_interface" "proxy_interface" {
  count     = "${length(var.availability_zones)}"
  subnet_id = "${element(var.proxy_subnets_id, count.index)}"

  security_groups = ["${aws_security_group.proxy_security_group.id}"]

  # Important to disable this check to allow traffic not addressed to the
  # proxy to be received
  source_dest_check = false

  tags = "${merge(var.tags, map("Name", "${var.env_name}-squid-proxy-interface-${element(var.availability_zones, count.index)}"))}"
}

resource "aws_security_group" "proxy_security_group" {
  name   = "${var.env_name}_proxy_security_group"
  vpc_id = "${var.vpc_id}"

  # SSH access from jumpbox security group
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = ["${var.squid_access_security_group_ids}"]
  }

  # Squid proxy port
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    self        = true
    cidr_blocks = ["${var.pcf_vpc_cidr}"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    self        = true
    cidr_blocks = ["${var.pcf_vpc_cidr}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${merge(var.tags, map("Name", "${var.env_name}-proxy-security-group"))}"
}
