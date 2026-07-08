output "alb_sg_id" {
  description = "ALB security group ID"
  value       = aws_security_group.alb.id
}

output "eks_nodes_sg_id" {
  description = "EKS nodes Security group ID"
  value       = aws_security_group.eks_nodes.id
}

output "rds_sg_id" {
  description = "RDS security group ID"
  value       = aws_security_group.rds.id
}

output "elasticache_sg_id" {
  description = "Elasticache security group ID"
  value       = aws_security_group.elasticache.id
}