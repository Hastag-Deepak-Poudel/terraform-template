data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  common_tags = {
    project     = var.naming_prefix
    environment = var.environment
  }

  naming_prefix = "${var.naming_prefix}-${var.environment}"
}