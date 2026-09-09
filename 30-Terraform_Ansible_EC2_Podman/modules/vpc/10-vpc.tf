resource "aws_vpc" "project_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  region = var.region
  tags = {
    "Name"         = "${var.project_name}"
    "controlledBy" = "terraform"
    "project"      = "${var.project_name}"
  }
}

resource "aws_default_route_table" "vpc_default_rtb" {
  region = var.region
  default_route_table_id = aws_vpc.project_vpc.default_route_table_id
  tags = {
    "Name"         = "${var.project_name}-default-rtb",
    "controlledBy" = "terraform",
  }
}

resource "aws_subnet" "public_subnet" {
  region = var.region
  vpc_id            = aws_vpc.project_vpc.id
  cidr_block        = var.subnets["public"].cidr
  availability_zone = var.subnets["public"].az
  map_public_ip_on_launch = true

  tags = {
    "Name"         = "${var.project_name}-public"
    "controlledBy" = "terraform"
    "project"      = "${var.project_name}"
  }
}
output "public_subnet_id" {
  value = aws_subnet.public_subnet.id
}

resource "aws_subnet" "private_subnet" {
  region = var.region
  vpc_id            = aws_vpc.project_vpc.id
  cidr_block        = var.subnets["private"].cidr
  availability_zone = var.subnets["private"].az

  tags = {
    "Name"         = "${var.project_name}-private"
    "controlledBy" = "terraform"
    "project"      = "${var.project_name}"
  }
}

#### Internet access for Public network
resource "aws_internet_gateway" "IGV" {
  vpc_id = aws_vpc.project_vpc.id
  region = var.region
  tags = {
    "Name"         = "${var.project_name}_IGW"
    "controlledBy" = "terraform"
    "project"      = "${var.project_name}"
  }
}

resource "aws_route_table" "IGW_RT" {
  vpc_id = aws_vpc.project_vpc.id
  region = var.region
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IGV.id
  }
  tags = {
    "Name"         = "${var.project_name}-IGW_RT"
    "controlledBy" = "terraform"
    "project"      = "${var.project_name}"
  }
}

resource "aws_route_table_association" "igw_rt_associate_with_pub_subnets" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.IGW_RT.id
}


