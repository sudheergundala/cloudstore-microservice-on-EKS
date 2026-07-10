output "table_name" {
  description = "The products table name"
  value       = aws_dynamodb_table.products.name
}

output "table_arn" {
  description = "The products table ARN"
  value       = aws_dynamodb_table.products.arn
}

output "table_streams_arn" {
  description = "The DynamoDB stream ARN (for the search-sync Lambda)"
  value       = aws_dynamodb_table.products.stream_arn
}

output "kms_key-arn" {
  description = "The CMK arn used for Dynamodb encryption"
  value       = aws_kms_key.dynamodb_key.arn
}