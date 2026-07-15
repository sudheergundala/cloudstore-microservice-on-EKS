output "product_images_bucket" {
  description = "Product images bucket name"
  value       = aws_s3_bucket.product_images.id
}

output "product_images_arn" {
  description = "Product images bucket ARN"
  value       = aws_s3_bucket.product_images.arn
}

output "invoices_bucket" {
  description = "Invoices bucket name"
  value       = aws_s3_bucket.invoices.id
}

output "invoices_arn" {
  description = "Invoices bucket ARN"
  value       = aws_s3_bucket.invoices.arn
}

output "logs_bucket" {
  description = "Logs bucket name"
  value       = aws_s3_bucket.logs.id
}

output "logs_arn" {
  description = "Logs bucket ARN"
  value       = aws_s3_bucket.logs.arn
}

output "kms_key_arn" {
  description = "The CMK ARN used for S3 encryption"
  value       = aws_kms_key.s3.arn
}