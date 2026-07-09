output "db_endpoint" {
  description = "RDS connection endpoint (host:port)"
  value       = aws_db_instance.this.endpoint
}

output "db_address" {
  description = "RDS hostname"
  value       = aws_db_instance.this.address
}

output "db_name" {
  description = "The database name"
  value       = aws_db_instance.this.db_name
}

output "db_secret_arn" {
  description = "Secrets Manager ARN holding the master password"
  value       = aws_db_instance.this.master_user_secret[0].secret_arn

}

output "kms_key_arn" {
  description = "The CMK ARN used for RDS encryption"
  value       = aws_kms_key.rds.arn
}