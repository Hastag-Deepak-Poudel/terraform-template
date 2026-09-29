################################################################################
# EKS Cluster
################################################################################
resource "aws_eks_cluster" "eks-cluster" {
  name     = var.cluster_config.name
  role_arn = aws_iam_role.EKSClusterRole.arn
  version  = var.cluster_config.version

  vpc_config {
    subnet_ids         = flatten([var.public_subnets_id, var.private_subnets_id])
    security_group_ids = flatten(var.security_groups_id)
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy
  ]

}

################################################################################
# NODE GROUP
################################################################################
resource "aws_eks_node_group" "node-ec2" {
  for_each        = { for node_group in var.node_groups : node_group.name => node_group }
  cluster_name    = aws_eks_cluster.eks-cluster.name
  node_group_name = "${var.naming_prefix}-${each.value.name}"
  node_role_arn   = aws_iam_role.NodeGroupRole.arn
  subnet_ids      = flatten(var.private_subnets_id)

  scaling_config {
    desired_size = try(each.value.scaling_config.desired_size, 2)
    max_size     = try(each.value.scaling_config.max_size, 3)
    min_size     = try(each.value.scaling_config.min_size, 1)
  }

  update_config {
    max_unavailable = try(each.value.update_config.max_unavailable, 1)
  }

  ami_type       = each.value.ami_type
  instance_types = each.value.instance_types
  capacity_type  = each.value.capacity_type
  disk_size      = each.value.disk_size
  version        = var.cluster_config.version

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-nodes-${each.value.name}"
  })

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy
  ]
}

resource "aws_iam_openid_connect_provider" "eks_oidc_provider" {
  url             = aws_eks_cluster.eks-cluster.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"]
}


################################################################################
# EKS Addons
################################################################################
data "aws_eks_addon_version" "eks_addons" {
  for_each = var.addons

  addon_name         = each.value.name
  kubernetes_version = aws_eks_cluster.eks-cluster.version
  most_recent        = coalesce(each.value.most_recent, true)
}

resource "aws_eks_addon" "addons" {
  for_each = var.addons

  cluster_name                = aws_eks_cluster.eks-cluster.name
  addon_name                  = each.value.name
  addon_version               = coalesce(each.value.version, data.aws_eks_addon_version.eks_addons[each.key].version)
  resolve_conflicts_on_create = "OVERWRITE"

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-addon-${each.value.name}"
  })

  depends_on = [aws_eks_node_group.node-ec2]
}
