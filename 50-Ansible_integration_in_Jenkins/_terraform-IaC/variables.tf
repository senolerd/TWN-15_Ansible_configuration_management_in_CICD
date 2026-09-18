variable "project_name" { type = string }
variable "environment" { type = string }
variable "instance_type" { type = string }
variable "keypair_name" { type = string } # on aws
variable "domain_name" { type = string }

# VPC settings
variable "region" { type = string }
variable "vpc_cidr" { type = string }
variable "subnets" {
  # ex: {subnet1 = { cidr = "10.10.1.0/24", az = "us-east-1a", is_public = false }}
  type = map(object({
    cidr      = string
    az        = string
    is_public = bool
  }))
}

# jenkins server apt packages
variable "jenkins_apt_pkcs" { type = list(string) }
variable "jenkins_plugins" { type = list(string) }

# ansible server apt packages
variable "ansible_ctl_apt_pkcs" { type = list(string) }

# workstation apt packages
variable "workstation_public_ports" { type = set(string) }
variable "workstation_apt_pkcs" { type = list(string) }
