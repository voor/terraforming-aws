variable "directory_password" {
  type = "password"
}

variable "directory_name" {
  type    = "string"
  default = ""
}

variable "env_name" {
  type = "string"
}

variable "dns_suffix" {
  type = "string"
}

variable "public_subnet_ids" {
  type = "list"
}

variable "tags" {
  type        = "map"
  default     = {}
  description = "Key/value tags to assign to all AWS resources"
}
