variable "vpc_id" {
  type = "string"
}

variable "env_name" {}

variable "public_subnet_ids" {
  type = "list"
}

variable "availability_zones" {
  type = "list"
}

variable "tags" {
  type        = "map"
  default     = {}
  description = "Key/value tags to assign to all AWS resources"
}

variable "use_route53" {
  default = false
}

variable "zone_id" {
  default = ""
}

variable "dns_suffix" {
  default = ""
}

variable "jumpbox_ami_id" {
}

