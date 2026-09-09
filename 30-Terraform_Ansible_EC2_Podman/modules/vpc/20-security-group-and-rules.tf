resource "aws_security_group" "deployment_SG" {
  region = var.region
  name   = "${var.project_name}_SG"
  vpc_id = aws_vpc.project_vpc.id
  tags = {
    "Name" = "${var.project_name}_SG"
  }
}

output "deployment_SG_id" {
  value = aws_security_group.deployment_SG.id
}

resource "aws_vpc_security_group_egress_rule" "name" {
  security_group_id = aws_security_group.deployment_SG.id
  cidr_ipv4 = "0.0.0.0/0"
  from_port = -1
  to_port = -1
  ip_protocol = -1
  description = "Allow all egress"
}

resource "aws_vpc_security_group_ingress_rule" "http-ingress" {
  # Create security group rule for each map in var.app_ports
  security_group_id = aws_security_group.deployment_SG.id
  for_each = var.allowed_ports
  cidr_ipv4      = each.value.allowed_cidr_ipv4
  from_port = each.value.port
  to_port = each.value.port
  ip_protocol = each.value.protocol
  description = each.value.description
  tags = {
    Name = "${var.project_name}-${each.key}-access"
    "controlledBy" = "terraform"
    "project"      = "${var.project_name}"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ssh_ingress_ipv4_incase" {
  security_group_id = aws_security_group.deployment_SG.id
  cidr_ipv4         = "${local.my_ipv4}/32"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  description       = "${var.project_name} ssh access from terrafrom installer allowing SSH for Ansible"
  tags = {
    Name = "${var.project_name}-SSH-access-to-ansible"
    "controlledBy" = "terraform"
    "project"      = "${var.project_name}"
  }
}

data "http" "my_ip4" {
  url = "https://ipv4.icanhazip.com"
}

locals {
  my_ipv4 = chomp(data.http.my_ip4.response_body)
}