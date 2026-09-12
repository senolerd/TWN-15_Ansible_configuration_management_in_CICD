resource "aws_instance" "ansible-controller" {
  ami                    = data.aws_ami.ubuntu.id
  key_name               = var.keypair_name
  instance_type          = var.instance_type
  subnet_id              = [for subnet in local.public_subnets : subnet.id][1]
  vpc_security_group_ids = [aws_security_group.ansible-controller-sg.id]
  region                 = var.region
  tags = {
    Name         = "${var.project_name}-Ansible"
    AnsibleGroup = "ansible_controller"
  }
  provisioner "local-exec" {
    working_dir = "ansible"
    command     = "ansible-playbook -i dynamic.aws_ec2.yaml 20-ansible-ctr-bootstrap.yaml"
  }
}

### Ansible SG ######
resource "aws_security_group" "ansible-controller-sg" {
  region = var.region
  name   = "ansible_controller"
  vpc_id = aws_vpc.project_vpc.id
  tags = {
    "Name" = "ansible_controller__at_${var.project_name}"
  }
}

resource "aws_vpc_security_group_egress_rule" "ansible-egress-allowed" {
  region            = var.region
  security_group_id = aws_security_group.ansible-controller-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = -1
  to_port           = -1
  ip_protocol       = -1
  description       = "Allow all egress"
}

resource "aws_vpc_security_group_ingress_rule" "ansible-ssh-for-myip-ipv4" {
  region            = var.region
  security_group_id = aws_security_group.ansible-controller-sg.id
  cidr_ipv4         = "${local.my_ip}/32"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  description       = "SSH access for my ip"
  tags = {
    Name = "Ansible-ssh-myip"
  }
}




















