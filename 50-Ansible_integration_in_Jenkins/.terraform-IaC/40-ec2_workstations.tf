
resource "aws_instance" "worker-node" {
  depends_on = [ aws_instance.ansible-controller ]
  count                  = 2
  ami                    = data.aws_ami.ubuntu.id
  key_name               = var.keypair_name
  instance_type          = var.instance_type
  subnet_id              = [for subnet in local.public_subnets : subnet.id][3]
  vpc_security_group_ids = [aws_security_group.workstations-sg.id]
  region                 = var.region
  tags = {
    Name         = "${var.project_name}_workstation_${count.index}"
    AnsibleGroup = "workstation"
  }

  # provisioner "local-exec" { 
    # only ansible node can access to this node management wise. So, 
    # anything to these nodes should be done by Jenkins triggered ansible playbooks
  # }
}

### Workstations SG ######
resource "aws_security_group" "workstations-sg" {
  region = var.region
  name   = "workstation"
  vpc_id = aws_vpc.project_vpc.id
  tags = {
    "Name" = "workstation_at_${var.project_name}"
  }
}

resource "aws_vpc_security_group_egress_rule" "workstations-egress-allowed" {
  region            = var.region
  security_group_id = aws_security_group.workstations-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = -1
  to_port           = -1
  ip_protocol       = -1
  description       = "Allow all egress"
}

# Workstations public ports 
resource "aws_vpc_security_group_ingress_rule" "workstations-public-ports" {
  region            = var.region
  security_group_id = aws_security_group.workstations-sg.id
  for_each          = var.workstation_public_ports
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = each.key
  to_port           = each.key
  ip_protocol       = "tcp"
  description       = "Public access for ${each.key}/tcp"
  tags = {
    Name = "workstation-${each.key}/tcp"
  }
}

# SSH access from Ansible Controller
resource "aws_vpc_security_group_ingress_rule" "ansibl-controller-access-for-workstation" {
  region            = var.region
  security_group_id = aws_security_group.workstations-sg.id
  cidr_ipv4         = "${aws_instance.ansible-controller.public_ip}/32"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  description       = "SSH access for Ansible Controller"
  tags = {
    Name = "ssh-from-ansible-controller"
  }
}
