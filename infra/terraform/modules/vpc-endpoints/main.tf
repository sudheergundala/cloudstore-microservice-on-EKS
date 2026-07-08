# S3 Gateway endpoint - route S3 traffic over VPC gateway endpoints(AWS backbone) - which is free of cost and secure.

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.private_route_table_ids
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-s3-endpoint"
  })
}

# DynamoDB Gateway endpoint - route DynamoDB traffic over VPC endpoint(AWS backbone) - free and secure. 

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = var.vpc_id
  route_table_ids   = var.private_route_table_ids
  service_name      = "com.amazonaws.${var.aws_region}.dynamodb"
  vpc_endpoint_type = "Gateway"
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-dynamodb-endpoint"
  })
}