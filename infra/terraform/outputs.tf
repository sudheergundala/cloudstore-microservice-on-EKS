
output "vpc_id" {
  description = "The VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "The VPC CIDR"
  value       = module.vpc.vpc_cidr
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "availability_zones" {
  description = "AZs used"
  value       = local.azs
}