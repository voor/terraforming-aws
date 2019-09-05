resource "aws_instance" "jumpbox" {
  count         = 1
  ami           = "${var.jumpbox_ami_id}"
  instance_type = "t2.micro"
  key_name      = "${aws_key_pair.jumpbox_pair.key_name}"

  subnet_id              = "${element(var.public_subnet_ids, count.index)}"
  vpc_security_group_ids = ["${aws_security_group.jumpbox_security_group.id}"]

  root_block_device {
    volume_type = "gp2"
    volume_size = 150
  }

  tags = "${merge(var.tags, map("Name", "${var.env_name}-jumpbox-${element(var.availability_zones, count.index)}"))}"
}

resource "aws_security_group" "jumpbox_security_group" {
  name   = "${var.env_name}_jumpbox_security_group"
  vpc_id = "${var.vpc_id}"

  # SSH access only
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${merge(var.tags, map("Name", "${var.env_name}-jumpbox-security-group"))}"
}

output "jumpbox_security_group_id" {
  value = "${aws_security_group.jumpbox_security_group.id}"
}

resource "aws_key_pair" "jumpbox_pair" {
  key_name   = "${var.env_name}-jumpbox-key"
  public_key = "${tls_private_key.jumpbox_key.public_key_openssh}"
}

resource "tls_private_key" "jumpbox_key" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

output "jumpbox_ssh_private_key" {
  value     = "${element(concat(tls_private_key.jumpbox_key.*.private_key_pem, list("")), 0)}"
  sensitive = true
}

resource "aws_eip" "jumpbox_eip" {
  count    = "1"
  vpc      = true
  instance = "${aws_instance.jumpbox.id}"

  tags = "${merge(var.tags, map("Name", "${var.env_name}-jumpbox-eip-${element(var.availability_zones, count.index)}"))}"
}

resource "aws_route53_record" "jumpbox_eip" {
  name    = "jumpbox.${var.env_name}.${var.dns_suffix}"
  zone_id = "${var.zone_id}"
  type    = "A"
  ttl     = 300
  count   = "${var.use_route53 ? 1 : 0}"

  records = ["${aws_eip.jumpbox_eip.public_ip}"]
}

output "jumpbox_dns" {
  value = "${element(concat(aws_route53_record.jumpbox_eip.*.name, list("")), 0)}"
}

locals {
  
}