
resource "aws_eks_cluster" "eks" {
  name = "${var.project_name}-${var.environment}"
  role_arn = aws_iam_role.cluster_role.arn
  version  = "1.36"

  access_config {
    authentication_mode = "API"
  }

  vpc_config {
    endpoint_private_access = true
    endpoint_public_access  = true
    subnet_ids              = [for subnet in var.private_subnets : subnet.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
  ]
  tags = { 
    "managedBy" : "terraform"
    "env": var.environment
  }  
}

###############################################################################################
resource "aws_iam_role" "cluster_role" {
  # Creating a role and associate policy for K8s service that can work on AWS.
  name = "eks-cluster-role-for-${var.project_name}-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster_role.name
}
###############################################################################################

# For "dev" environment, adding EKS clusters default SG to VPC Endpoints SG
# for allowing incoming request from node groups to endpoints
resource "aws_vpc_security_group_ingress_rule" "vpc_security_group_ingress_rule" {
  count = var.environment == "dev" ? 1 : 0
  security_group_id            = var.vpc_endpoint_sg_for_eks_id
  referenced_security_group_id = aws_eks_cluster.eks.vpc_config[0].cluster_security_group_id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
}


###############################################################################################

# This IAM user (the IAM account used by Terraform now) access entry for EKS cluster
# EKS access entry and its role for the user whose access key is used for this Terraform config.
# Without this, EKS console looks so messy because this user doesn't have access to see
# whats going inside the EKS cluster. 
  
data "aws_caller_identity" "whoami" {}

resource "aws_eks_access_entry" "eks_access_entry_for_whoami" {
  cluster_name  = aws_eks_cluster.eks.name
  principal_arn = data.aws_caller_identity.whoami.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "eks_access_policy_association_to_whoami" {
  depends_on = [ aws_eks_access_entry.eks_access_entry_for_whoami ]
  cluster_name  = aws_eks_cluster.eks.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = data.aws_caller_identity.whoami.arn
  access_scope {
    type = "cluster"
  }
}

###############################################################################################