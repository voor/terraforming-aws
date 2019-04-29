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
  defaut = false
}

variable "zone_id" {
  default = ""
}
