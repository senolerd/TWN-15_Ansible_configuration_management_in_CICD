variable "region" { type = string }
variable "vpc_cidr" { type = string }
variable "project_name" { type = string }
variable "keypair_name" { type = string }

variable "environment" {
  description = "dev or prod"
  type = string
  default = "dev"
}

variable "endpoints_interface" { 
  # These endpoints will be in use for "dev" environment because private subnets will not have egress (nor IGW neither NatGW )
  description = "A set of service names for endpoint interfaces (not gateway), like ('ecr.api', 'ecr.dkr', 'ec2')"
  type = set(string) 
  }


variable "instance_types" { 
  description = "list of image types that can be used by node group creation"
  type = map(list(string))
}

variable "subnets" {
  type = map(object({
    cidr      = string
    az        = string
    is_public = bool
  }))
}

variable "vpc_endpoint_sg_for_eks_id" {
  type = string
  default = null
}



variable "domain_name" {
  type = string
}

variable "project_httproutes" {
  type = list(object({
    hostname = string
    svc_name = string
    svc_port = number
    svc_ns = string
  }))
}


