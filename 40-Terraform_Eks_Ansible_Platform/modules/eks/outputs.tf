
data "aws_eks_cluster_auth" "this" {
  depends_on = [aws_eks_cluster.eks]
  name = aws_eks_cluster.eks.name
}

data "aws_eks_cluster" "this" {
  name = aws_eks_cluster.eks.name
}

############################################# 
output "cluster" {
  value = data.aws_eks_cluster.this
}

output "cluster_auth" {
  value = data.aws_eks_cluster_auth.this
}


# output "nodegroup" {
#   value = aws_eks_node_group.ng1
# }