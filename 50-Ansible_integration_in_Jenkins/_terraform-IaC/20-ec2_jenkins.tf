resource "aws_instance" "jenkins" {
  ami                    = data.aws_ami.ubuntu.id
  key_name               = var.keypair_name
  instance_type          = var.instance_type
  subnet_id              = [for subnet in local.public_subnets : subnet.id][0]
  vpc_security_group_ids = [aws_security_group.jenkins-sg.id]
  region                 = var.region

  tags = {
    Name = "${var.project_name}-Jenkins"
    AnsibleGroup = "jenkins_controller"
  }

  provisioner "local-exec" {
    working_dir = "ansible"
    command = "ansible-playbook 10-jenkins-bootstrap.yaml"
  }
}

### Jenkins SG ######
resource "aws_security_group" "jenkins-sg" {
  region = var.region
  name = "jenkins"
  vpc_id = aws_vpc.project_vpc.id
  tags = {
    "Name" = "jenkins__at_${var.project_name}"
  }
}

resource "aws_vpc_security_group_egress_rule" "jenkins-egress-allowed" {
  region            = var.region
  security_group_id = aws_security_group.jenkins-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = -1
  to_port           = -1
  ip_protocol       = -1
  description       = "Allow all egress"
}

resource "aws_vpc_security_group_ingress_rule" "jenkins-web-for-myip-ipv4" {
  region            = var.region
  security_group_id = aws_security_group.jenkins-sg.id
  cidr_ipv4         = "${local.my_ip}/32"
  from_port         = 8080
  to_port           = 8080
  ip_protocol       = "tcp"
  description       = "Jenkins access for my ip"
  tags = {
    Name = "Jenkins-myip"
  }
}

resource "aws_vpc_security_group_ingress_rule" "jenkins-ssh-for-myip-ipv4" {
  region            = var.region
  security_group_id = aws_security_group.jenkins-sg.id
  cidr_ipv4         = "${local.my_ip}/32"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  description       = "Jenkins access for my ip"
  tags = {
    Name = "Jenkins-myip"
  }
}


resource "aws_vpc_security_group_ingress_rule" "jenkins-webhook-allow-ipv4" {
  region            = var.region
  security_group_id = aws_security_group.jenkins-sg.id
  for_each = local.ipv4_hooks
  cidr_ipv4         = each.value
  from_port         = 8080
  to_port           = 8080
  ip_protocol       = "tcp"
  description       = "github-webhook access of ${each.value} v4"
  tags = {
    Name = "GitHub-WHv4-${each.value}"
  }
}

resource "aws_vpc_security_group_ingress_rule" "jenkins-webhook-allow-ipv6" {
  region            = var.region
  security_group_id = aws_security_group.jenkins-sg.id
  for_each = local.ipv6_hooks
  cidr_ipv6         = each.value
  from_port         = 8080
  to_port           = 8080
  ip_protocol       = "tcp"
  description       = "github-webhook access of ${each.value} v6"
  tags = {
    Name = "GitHub-WHv6-${each.value}"
  }
}










