module "vpc" {
  source        = "./modules/vpc"
  project_name  = var.project_name
  region        = var.region
  subnets       = var.subnets
  vpc_cidr      = var.vpc_cidr
  instance_type = var.instance_type
  allowed_ports = var.allowed_ports
}
