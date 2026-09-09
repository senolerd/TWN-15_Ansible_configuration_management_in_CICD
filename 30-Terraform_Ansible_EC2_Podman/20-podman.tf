resource "aws_instance" "podman_server" {
  depends_on             = [module.vpc]
  ami                    = data.aws_ami.ubuntu.id
  key_name               = var.keypair_name
  instance_type          = var.instance_type
  subnet_id              = module.vpc.public_subnet_id
  vpc_security_group_ids = [module.vpc.deployment_SG_id]
  region                 = var.region
  tags = {
    Name         = "${var.project_name}-Podman-Server"
    AnsibleGroup = "podman_server"
  }

  provisioner "local-exec" {
    working_dir = "ansible"
    command     = <<-EOT
          ansible-playbook -i podman_servers.aws_ec2.yml java-maven-on-ec2-podman.yaml \
          --private-key ${var.keypair_pem} -u ${var.remote_ec2_user} \
          -e "oci_registry=${var.oci_registry}" \
          -e "oci_registry_user=${var.oci_registry_user}" \
          -e "oci_repo=${var.oci_repo}" \
          -e "pod_name=${var.pod_name}" \
          -e "host_port=${var.host_port}" \
          -e "container_port=${var.container_port}" 
      EOT
  }
}

resource "aws_instance" "testserver" {
  depends_on             = [module.vpc]
  ami                    = data.aws_ami.ubuntu.id
  key_name               = var.keypair_name
  instance_type          = "t3a.nano"
  subnet_id              = module.vpc.public_subnet_id
  vpc_security_group_ids = [module.vpc.deployment_SG_id]
  region                 = var.region
  tags = {
    Name  = "testserver"
    Hello = "World"
  }
}














data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
