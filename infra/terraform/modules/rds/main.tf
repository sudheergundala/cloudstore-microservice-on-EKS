

# KMS KEY - customer managed key(CMK) for RDS encryption.

resource "aws_kms_key" "rds" {
  description             = "CMK for ${var.name_prefix} RDS encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-rds-kms"
  })
}

# friendly alias for the KMS key

resource "aws_kms_alias" "rds" {
  name          = "alias/${var.name_prefix}-rds"
  target_key_id = aws_kms_key.rds.key_id
}

# DB SUBNET GROUP -  the private subnets where the RDS launches into

resource "aws_db_subnet_group" "this" {
  name       = "${var.name_prefix}-db-subnet-group"
  subnet_ids = var.private_subnet_ids
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-db-subnet-group"
  })
}

# DB  PARAMETER Group - enforce SSL/TLS for connections in transit 

resource "aws_db_parameter_group" "this" {
  name   = "${var.name_prefix}-postgres16"
  family = "postgres16"
  parameter {
    name  = "rds.force_ssl"
    value = "1" # require SSL/TLS for all connections
  }
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-postgres-params"
  })
  lifecycle {
    create_before_destroy = true
  }

}

# RDS Instance - PostgreSQL, Encrypted, HA-capable, Private

resource "aws_db_instance" "this" {
  identifier = "${var.name_prefix}-orders-db"

  # Engine
  engine         = "postgres"
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  # Storage(encrypted with CMK, autoscaling enabled)
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_encrypted     = true
  storage_type          = "gp3"
  kms_key_id            = aws_kms_key.rds.arn

  # Database and Credentials

  db_name  = var.db_name
  username = "cloudstore"
  # RDS generates and manages the password in secrets manager, auto-rotated. So no password argument.
  manage_master_user_password   = true
  master_user_secret_kms_key_id = aws_kms_key.rds.arn

  # Network (private subnet, restricted SG, never public)

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.rds_security_group_id]
  publicly_accessible    = false
  port                   = 5432

  # Enforce SSL/TLS via parameter group

  parameter_group_name = aws_db_parameter_group.this.name

  # Multi-AZs(High Availability)

  multi_az = var.multi_az

  # Backups (enable point-in-time-recovery)

  backup_retention_period = var.backup_retention_period
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"

  # Protection
  deletion_protection = var.deletion_protection
  skip_final_snapshot = var.skip_final_snapshot

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-orders-db"
  })

}