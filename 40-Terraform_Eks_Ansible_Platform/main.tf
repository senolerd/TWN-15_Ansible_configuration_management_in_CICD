# Update terraform.tfvars for new deployment environment 

module "vpc" {
  source              = "./modules/vpc"
  project_name        = var.project_name
  region              = var.region
  environment         = var.environment
  subnets             = var.subnets
  vpc_cidr            = var.vpc_cidr
  endpoints_interface = var.endpoints_interface
}

module "eks" {
  depends_on                 = [module.vpc]
  source                     = "./modules/eks"
  project_name               = var.project_name
  environment                = var.environment
  region                     = var.region
  private_subnets            = module.vpc.private_subnets
  keypair_name               = var.keypair_name
  vpc_endpoint_sg_for_eks_id = module.vpc.vpc_endpoint_sg_for_eks_id
  instance_types             = var.instance_types
}


resource "terraform_data" "pull_cluster_config" {
  # EKS post installs preparing cluster essentials, like; pulling kubeconfig, installing Gateway API CRDs, LBC, ArgoCD
  depends_on = [ module.eks ]
  triggers_replace = {  always_run = timestamp() }
  input = {
    cluster_name = "${var.project_name}-${var.environment}"
    region = var.region
    env = var.environment
    project_name = var.project_name
    vpc_id = module.vpc.vpc_id
    project_httproutes =  var.project_httproutes
  }

  provisioner "local-exec" {
    # Post installation for newly span up EKS, like; LBC, Gateway API CRDs, ArgoCD
    working_dir = "ansible"
    when = create
    command = <<-EOT
      aws eks update-kubeconfig --name ${self.input.cluster_name} --region ${self.input.region} --kubeconfig ../kubeconfig-${self.input.cluster_name}

      python3 -m venv .venv 
      .venv/bin/python3 -m pip install --upgrade pip
      .venv/bin/pip install -r ${path.cwd}/requirements.txt

      ansible-playbook -i localhost, lbc-install.yaml \
        -e "region=${self.input.region} cluster_name=${module.eks.cluster.id} env=${self.input.env} project_name=${self.input.project_name} vpc_id=${self.input.vpc_id} " \
        -e "ansible_python_interpreter=.venv/bin/python3" -e '${jsonencode({ project_httproutes = self.input.project_httproutes })}'

    EOT
  }

  provisioner "local-exec" {
    when = destroy
    command = "rm -f kubeconfig-${self.input.cluster_name}"
  }
}
