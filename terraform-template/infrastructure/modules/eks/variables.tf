variable "common_tags" {}
variable "naming_prefix" {}

variable "public_subnets_id" {}

variable "private_subnets_id" {}

variable "security_groups_id" {}

variable "cluster_config" {}

variable "node_groups" {
  type = list(object({
    name           = string
    instance_types = list(string)
    ami_type       = string
    capacity_type  = string
    disk_size      = number
    scaling_config = object({
      desired_size = number
      min_size     = number
      max_size     = number
    })
    update_config = object({
      max_unavailable = number
    })
  }))
  default = [
    {
      name           = "CT-EKS-Cluster-Node-Group"
      instance_types = ["t3.medium"]
      ami_type       = "AL2023_x86_64_STANDARD"
      capacity_type  = "ON_DEMAND"
      disk_size      = 20
      scaling_config = {
        desired_size = 2
        max_size     = 3
        min_size     = 1
      }
      update_config = {
        max_unavailable = 1
      }
    },
  ]

}

variable "addons" {
  type = map(object({
    name        = string
    version     = optional(string)
    most_recent = optional(bool, true)
  }))
  description = "Map of EKS addons to install. When most_recent is true, the latest compatible version will be used."

  default = {
    kube-proxy = {
      name        = "kube-proxy"
      most_recent = true
    }
    vpc-cni = {
      name        = "vpc-cni"
      most_recent = true
    }
    coredns = {
      name        = "coredns"
      most_recent = true
    }
  }
}