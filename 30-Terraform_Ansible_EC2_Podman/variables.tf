
variable "project_name" { type = string }
variable "region" { type = string }
variable "vpc_cidr" { type = string }
variable "keypair_name" { type = string }
variable "keypair_pem" { type = string }
variable "remote_ec2_user" { type = string }


variable "instance_type" { 
  type = string
}

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

variable "oci_registry" { type = string }
variable "oci_registry_user" { type = string }
variable "oci_repo" { type = string }
variable "pod_name" { type = string }
variable "host_port" { type = number }
variable "container_port" { type = number }



