resource "aws_eks_node_group" "ng1" {
  cluster_name    = aws_eks_cluster.eks.name
  region = var.region
  node_group_name = "ng-${aws_eks_cluster.eks.name}"
  node_role_arn   = aws_iam_role.role_for_nodegroup.arn
  subnet_ids      = [for subnet in var.private_subnets : subnet.id]
  instance_types  = var.environment == "dev" ? var.instance_types.dev : var.instance_types.prod

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_eks_addon.kube-proxy,
    aws_eks_addon.vpc-cni,
    aws_iam_role_policy_attachment.ng-role-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.ng-role-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.ng-role-AmazonEC2ContainerRegistryReadOnly,
    aws_eks_access_entry.eks_access_entry_for_whoami
  ]
  tags = { 
    "managedBy" : "terraform"
    "env": var.environment
  }
}

resource "aws_iam_role" "role_for_nodegroup" {
  name = "eks-nodegroup-role-${aws_eks_cluster.eks.name}"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "ng-role-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.role_for_nodegroup.name
}

resource "aws_iam_role_policy_attachment" "ng-role-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.role_for_nodegroup.name
}

resource "aws_iam_role_policy_attachment" "ng-role-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.role_for_nodegroup.name
}

resource "aws_iam_role_policy_attachment" "nodes_ssm" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.role_for_nodegroup.name
}
