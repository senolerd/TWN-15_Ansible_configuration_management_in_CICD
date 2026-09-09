project_name = "my-project"
region       = "us-east-1"
vpc_cidr = "10.10.0.0/16"
subnets = {
  public = { cidr = "10.10.1.0/24", az = "us-east-1a"}
  private = { cidr = "10.10.2.0/24", az = "us-east-1a"}
}
instance_type = "t3.micro"
keypair_name = "devops-key" # this key-pair's private key will be used by Ansible playbook
keypair_pem = "~/Downloads/devops-key.pem"
remote_ec2_user = "ubuntu"

oci_registry= "docker.io"
oci_registry_user= "alkol"
oci_repo= "java-maven-app:1.1.0-SNAPSHOT-832e0be-b81"
pod_name= "myproject"
host_port= 3000
container_port= 8080

allowed_ports = {
    "pod" = {
    allowed_cidr_ipv4 = "0.0.0.0/0"
    port = 3000
    protocol = "tcp"
    description = "pod access"
  },
  # "http" = {
  #   allowed_cidr_ipv4 = "0.0.0.0/0"
  #   port = 80
  #   protocol = "tcp"
  #   description = "http access"
  # },
  # "https" = {
  #   allowed_cidr_ipv4 = "0.0.0.0/0"
  #   port = 443
  #   protocol = "tcp"
  #   description = "https access"
  # },
  # "ssh" = { # ssh will be open hard-coded to terraforum runner IPv4 address
  #   allowed_cidr_ipv4 = "0.0.0.0/0"
  #   port = 22
  #   protocol = "tcp"
  #   description = "SSH access"
  # }
}

