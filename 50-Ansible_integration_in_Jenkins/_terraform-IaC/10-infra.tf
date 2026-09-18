resource "aws_vpc" "project_vpc" {
  cidr_block           = var.vpc_cidr
  region               = var.region
  enable_dns_hostnames = true
  tags = {
    "Name"      = "${var.project_name}-${var.environment}-"
    "managedBy" = "terraform"
    "project"   = "${var.project_name}"
  }
}

resource "aws_default_route_table" "name" {
  region                 = var.region
  default_route_table_id = aws_vpc.project_vpc.default_route_table_id
  tags = {
    "Name"      = "${var.environment}-${var.project_name}-default"
    "managedBy" = "terraform"
    "env"       = var.environment
  }
}

resource "aws_subnet" "project_subnets" {
  vpc_id                  = aws_vpc.project_vpc.id
  region                  = var.region
  for_each                = var.subnets
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = each.value.is_public
  tags = {
    "Name" : "${var.environment}-${var.project_name}-${each.value.az}-${each.value.is_public ? "public" : "priv"}"
    "is_public"              = each.value.is_public
    "managedBy"              = "terraform"
    "project"                = "${var.project_name}"
    "kubernetes.io/role/elb" = each.value.is_public ? 1 : 0
    "env"                    = var.environment
  }
}

#### IGW
resource "aws_internet_gateway" "IGV" {
  region = var.region
  vpc_id = aws_vpc.project_vpc.id
  tags = {
    "Name"      = "${var.environment}-${var.project_name}_IGW"
    "managedBy" = "terraform"
    "env"       = var.environment
    "project"   = "${var.project_name}"
  }
}

resource "aws_route_table" "IGW-RT" {
  region = var.region
  vpc_id = aws_vpc.project_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IGV.id
  }
  tags = {
    "Name"      = "${var.environment}-${var.project_name}-IGW_RT"
    "managedBy" = "terraform"
    "env"       = var.environment
    "project"   = "${var.project_name}"
  }
}

resource "aws_route_table_association" "igw_rt_associate_with_pub_subnets" {
  region         = var.region
  for_each       = local.public_subnets
  subnet_id      = each.value.id
  route_table_id = aws_route_table.IGW-RT.id
}

locals {
  public_subnets = {
    for k, subnet in aws_subnet.project_subnets :
    k => subnet
    if var.subnets[k].is_public == true
  }

  private_subnets = {
    for k, subnet in aws_subnet.project_subnets :
    k => subnet
    if var.subnets[k].is_public == false
  }

  my_ip            = chomp(data.http.my_public_ip.response_body)
  github_meta_data = jsondecode(data.http.github_meta_api.response_body)
  ipv4_hooks       = toset([for item in local.github_meta_data.hooks : item if !can(regex(":", item))])
  ipv6_hooks       = toset([for item in local.github_meta_data.hooks : item if can(regex(":", item))])
}

data "http" "github_meta_api" {
  # pulling github metadata to scrape webhook servers that will send signals for 
  # triggering Jenkins builds (if planned to have). locals{} will take care classify pulled data.
  # Then, those ip addresses (v4|v6) will be added to Jenkins Security Group ingress rules.
  url = "https://api.github.com/meta"
}

data "http" "my_public_ip" {
  url = "https://api.ipify.org"
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
