variable "project_name" {type = string }
variable "region" { type = string }
variable "vpc_cidr" { type = string }
variable "instance_type" { type = string }

variable "subnets" {
  type = map(object({
    cidr      = string
    az        = string
  }))
}

variable "allowed_ports" {
  type = map(object({
    allowed_cidr_ipv4      = string
    port = number
    protocol = string
    description = string
  }))
}



