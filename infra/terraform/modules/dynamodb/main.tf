# Products table -- No SQL catalog store
# Partition key: id | GSI: category | streams for search-sync

resource "aws_kms_key" "dynamodb_key" {
  description             = "CMK for ${var.name_prefix}-dynamodb encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-dynamodb-kms"
  })
}

resource "aws_kms_alias" "dynamodb_key" {
  name          = "alias/${var.name_prefix}-dynamodb"
  target_key_id = aws_kms_key.dynamodb_key.key_id
}

resource "aws_dynamodb_table" "products" {
  name         = "${var.name_prefix}-products"
  billing_mode = var.billing_mode
  hash_key     = "id"
  # Only declear key attributes(table key + index keys)
  # declearing non-key attributes cause phantom drift (infinite loop)

  attribute {
    name = "id"
    type = "S" #string
  }
  attribute {
    name = "category"
    type = "S"
  }

  # GSI: query products by category ( a different partition key)

  global_secondary_index {
    name            = "category-index"
    hash_key        = "category"
    projection_type = "ALL" # include all attributes in the index
  }

  # point-in-time-recovery - continous backups, 35-day restore window

  point_in_time_recovery {
    enabled = true
  }

  # Encryption at rest with CMK

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.dynamodb_key.arn
  }

  # Streams - capture every change for search-sync lambda(CDC)

  stream_enabled   = var.enable_streams
  stream_view_type = var.enable_streams ? "NEW_AND_OLD_IMAGES" : null

  # Delete protection (false for dev so that we can delete)

  deletion_protection_enabled = var.deletion_protection

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-products"
  })
}