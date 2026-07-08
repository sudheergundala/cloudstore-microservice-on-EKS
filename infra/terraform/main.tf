data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  name_prefix  = "cloudstore-${var.environment}"
  cluster_name = "cloudstore-${var.environment}"

  azs = slice(data.aws_availability_zones.available.names, 0, 3)

  common_tags = {
    Project     = "cloudstore"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

module "vpc" {
  source             = "./modules/vpc"
  vpc_cidr           = var.vpc_cidr
  name_prefix        = local.name_prefix
  cluster_name       = local.cluster_name
  availability_zones = local.azs
  tags               = local.common_tags
}

module "security_groups" {
  source      = "./modules/security-groups"
  vpc_id      = module.vpc.vpc_id
  name_prefix = local.name_prefix
  tags        = local.common_tags
}

module "vpc-endpoints" {
  source                  = "./modules/vpc-endpoints"
  private_route_table_ids = module.vpc.private_route_table_ids
  vpc_id                  = module.vpc.vpc_id
  name_prefix             = local.name_prefix
  aws_region              = var.aws_region
  tags                    = local.common_tags
}