# Full addon list for default console EKS install
# - Amazon EKS Pod Identity Agent
# - Amazon VPC CNI (role needed)
# - kube-proxy 
# - CoreDNS 

# - External DNS (role needed)
# - Node monitoring agent
# - Metrics Server


###### Pod Identity agent addon (Default for installing with EKS console normal mode)
resource "aws_eks_addon" "eks-pod-identity-agent" {
  cluster_name = aws_eks_cluster.eks.name
  addon_name   = "eks-pod-identity-agent"
  addon_version = "v1.3.10-eksbuild.3"
  resolve_conflicts_on_update = "PRESERVE"
}

###### Amazon VPC CNI (Default for installing with EKS console normal mode)
resource "aws_eks_addon" "vpc-cni" {
  depends_on = [ aws_eks_addon.eks-pod-identity-agent ]
  cluster_name                = aws_eks_cluster.eks.name
  addon_name                  = "vpc-cni"
  addon_version               = "v1.22.3-eksbuild.1"
  resolve_conflicts_on_update = "PRESERVE"
  pod_identity_association {
    role_arn = aws_iam_role.role-for-pods.arn
    service_account = "aws-node"
  }
  namespace_config {
    namespace = "kube-system"
  }
}

resource "aws_iam_role" "role-for-pods" {
  name = "pod-identity-role-for-${aws_eks_cluster.eks.name}-vpc-cni"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "pods.eks.amazonaws.com"
        },
        "Action" : [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "pod-role-policy-attachment" {
  role       = aws_iam_role.role-for-pods.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}


###### kube-proxy (Default for installing with EKS console normal mode)
resource "aws_eks_addon" "kube-proxy" {
  depends_on = [ aws_eks_cluster.eks ]
  cluster_name = aws_eks_cluster.eks.name
  addon_name   = "kube-proxy"
  addon_version = "v1.36.0-eksbuild.13"
  resolve_conflicts_on_update = "PRESERVE"
}


##### coredns (Default for installing with EKS console normal mode)
resource "aws_eks_addon" "coredns" {
  depends_on = [ aws_eks_node_group.ng1 ]
  cluster_name = aws_eks_cluster.eks.name
  addon_name   = "coredns"
  addon_version = "v1.14.3-eksbuild.3"
  resolve_conflicts_on_update = "PRESERVE"
}

