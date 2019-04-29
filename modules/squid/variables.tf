variable "ssl_ca_cert" {}

variable "ssl_ca_private_key" {}

variable "squid_docker_image" {
  default = "voor/squid4"
}

variable "availability_zones" {
  type = "list"
}

variable "env_name" {}

variable "proxy_subnets_id" {
  type = "list"
}

variable "squid_access_security_group_ids" {
  type    = "list"
  default = ""
}
