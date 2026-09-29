variable "common_tags" {}
variable "naming_prefix" {}
variable "cluster_name" {}

variable "networking" {
  description = "VPC networking configuration passed from root module"
}

variable "security_groups" {
  description = "Security groups configuration passed from root module"
}