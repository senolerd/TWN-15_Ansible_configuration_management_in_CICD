project_name = "my-proj"
region       = "us-east-1"
environment = "prod"
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

# for dev environment
# endpoints_interface = [ "ecr.api", "ecr.dkr", "ec2", "sts", "eks-auth", "elasticloadbalancing" ]
endpoints_interface = [ ]


instance_types = {
  dev =  ["t3.small"] 
  prod = ["t3.small"]
} 
keypair_name = "senol-mac"

domain_name = "senolerd.xyz"


project_httproutes = [ 
    {hostname="argo", svc_name = "argocd-server", svc_port = 8080, svc_ns = "argocd"},
    {hostname="jenkins", svc_name = "jenkins", svc_port = 8080, svc_ns = "jenkins"}
  ]