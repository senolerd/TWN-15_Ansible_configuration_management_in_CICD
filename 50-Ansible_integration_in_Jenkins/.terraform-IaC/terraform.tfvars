project_name = "ansible-jenkins"
region       = "us-east-1"
environment = "prod"
instance_type = "t3.small"
keypair_name = "devops-key" #on aws
keypair_pem_local = "~/.ssh/id_rsa" # local location
domain_name = "senolerd.xyz"


# VPC settings
vpc_cidr = "10.10.0.0/16"
subnets = {
  subnet1 = { cidr = "10.10.1.0/24", az = "us-east-1a", is_public = false }
  subnet2 = { cidr = "10.10.2.0/24", az = "us-east-1a", is_public = true }
  subnet3 = { cidr = "10.10.3.0/24", az = "us-east-1b", is_public = false }
  subnet4 = { cidr = "10.10.4.0/24", az = "us-east-1b", is_public = true }
  subnet5 = { cidr = "10.10.5.0/24", az = "us-east-1c", is_public = false }
  subnet6 = { cidr = "10.10.6.0/24", az = "us-east-1c", is_public = true }
  subnet7 = { cidr = "10.10.7.0/24", az = "us-east-1d", is_public = false }
  subnet8 = { cidr = "10.10.8.0/24", az = "us-east-1d", is_public = true }
}

# Jenkins bootstrap settings
jenkins_apt_pkcs= ["openjdk-25-jre", "ansible", "python3-boto3"]
jenkins_plugins=["ssh-agent"]

# Ansible bootstrap settings
ansible_ctl_apt_pkcs=["ansible", "python3-boto3"]

# Workstations bootstrap settings
workstation_apt_pkcs=[]
workstation_public_ports = ["80", "443", "8080"]
