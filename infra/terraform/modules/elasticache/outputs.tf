output "primary_endpoint" {
  description = "Primary endpoint (writes)"
  value       = aws_elasticache_replication_group.this.primary_endpoint_address
}

output "reader_endpoint" {
  description = "Reader endpoint (load-balanced reads across replicas)"
  value       = aws_elasticache_replication_group.this.reader_endpoint_address
}

output "auth_token_secret_arn" {
  description = "Secrets Manager ARN holding the cache auth token"
  value       = aws_secretsmanager_secret.elasticache.arn
}

output "kms_key_arn" {
  description = "The CMK ARN used for cache encryption"
  value       = aws_kms_key.elasticache.arn
}