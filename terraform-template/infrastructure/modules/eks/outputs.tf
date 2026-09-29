################################################################################
# EKS Cluster Outputs
################################################################################

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.eks-cluster.endpoint
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.eks-cluster.name
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.eks-cluster.certificate_authority[0].data
}

output "cluster_id" {
  description = "EKS cluster ID"
  value       = aws_eks_cluster.eks-cluster.id
}

output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = aws_eks_cluster.eks-cluster.arn
}

output "cluster_version" {
  description = "The Kubernetes version for the cluster"
  value       = aws_eks_cluster.eks-cluster.version
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_eks_cluster.eks-cluster.vpc_config[0].cluster_security_group_id
}

output "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider for the EKS cluster"
  value       = aws_iam_openid_connect_provider.eks_oidc_provider.arn
}

output "node_groups" {
  description = "Map of EKS node group information"
  value = {
    for ng_name, ng in aws_eks_node_group.node-ec2 : ng_name => {
      arn            = ng.arn
      status         = ng.status
      capacity_type  = ng.capacity_type
      instance_types = ng.instance_types
      scaling_config = ng.scaling_config
    }
  }
}