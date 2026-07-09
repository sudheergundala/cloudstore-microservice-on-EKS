
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

output "alb_sg_id" {
  description = "ALB security group ID"
  value       = module.security_groups.alb_sg_id
}

output "eks_nodes_sg_id" {
  description = "EKS nodes security group ID"
  value       = module.security_groups.eks_nodes_sg_id
}

output "rds_sg_id" {
  description = "RDS security group id"
  value       = module.security_groups.rds_sg_id
}

output "elasticache_sg_id" {
  description = "Elasticache security group id"
  value       = module.security_groups.elasticache_sg_id
}

output "rds_endpoint" {
  description = "RDS connection endpoint"
  value       = module.rds.db_endpoint
}

output "rds_secret_arn" {
  description = "Secrets Manager ARN for the DB password"
  value       = module.rds.db_secret_arn
  sensitive   = true
}