output "s3_endpoint_id" {
  description = "s3 gateway endpoint ID"
  value       = aws_vpc_endpoint.s3
}

output "dynamodb_endpoint_id" {
  description = "dynamodb gateway endpoint ID"
  value       = aws_vpc_endpoint.dynamodb
}