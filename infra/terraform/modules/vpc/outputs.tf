output "vpc_id" {
  description = "The VPC ID"
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "The VPC CIDR block"
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "List of public subnet ids"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet ids"
  value       = aws_subnet.private[*].id
}

output "natgateway_ids" {
  description = "List of NAT gateway ids"
  value       = aws_nat_gateway.this[*].id
}

output "public_route_table_id" {
  description = "The Public route table ID"
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "List of Private route tables IDs"
  value       = aws_route_table.private[*].id
}
