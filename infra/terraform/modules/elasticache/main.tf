# Dedicated CMK for the elasticache encryption - KMS key

resource "aws_kms_key" "elasticache" {
  description             = "CMK for ${var.name_prefix} Elasticache encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-elasticache-kms"
  })
}

resource "aws_kms_alias" "elasticache" {
  name          = "alias/${var.name_prefix}-elasticache"
  target_key_id = aws_kms_key.elasticache.key_id
}

# Auth-token : generated password, stored in scerets manager
# Elasticahe has no AWS managed password like our DBs so we need to generate it.

resource "random_password" "elasticache" {
  length           = 32
  special          = true
  override_special = "!#$&^<>-" # elasticache allowed special characters only
}

resource "aws_secretsmanager_secret" "elasticache" {
  name                    = "${var.name_prefix}-elasticache-auth-token"
  kms_key_id              = aws_kms_key.elasticache.arn
  recovery_window_in_days = 0 # for dev: immediate deletion so that we can recreate
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-elasticache-auth-token"
  })
}

resource "aws_secretsmanager_secret_version" "elasticache" {
  secret_id     = aws_secretsmanager_secret.elasticache.id
  secret_string = random_password.elasticache.result
}

# cache subnet group - the private subnets the cache lives in 

resource "aws_elasticache_subnet_group" "elasticache" {
  name       = "${var.name_prefix}-cache-subnet-group"
  subnet_ids = var.private_subnet_ids
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-cache-subnet-groups"
  })
}

# Replication group - valkey, cluster-mode-disabled, HA, Encrypted

resource "aws_elasticache_replication_group" "this" {
  description          = "Valkey for ${var.name_prefix}"
  replication_group_id = "${var.name_prefix}-cache"
  engine               = "valkey"
  engine_version       = var.engine_version
  node_type            = var.node_type
  port                 = 6379

  # cluster mode disabled(1 primary + N-1 replicas)

  num_cache_clusters         = var.num_cache_cluster
  multi_az_enabled           = var.multi_az
  automatic_failover_enabled = var.automatic_failover

  # Network (private subnets + SG)

  subnet_group_name  = aws_elasticache_subnet_group.elasticache.name
  security_group_ids = [var.elasticache_security_group_id]

  # Encryption at rest + TLS required for valkey

  at_rest_encryption_enabled = true
  kms_key_id                 = aws_kms_key.elasticache.arn
  transit_encryption_enabled = true
  auth_token                 = random_password.elasticache.result

  # backups

  snapshot_retention_limit = var.snapshot_retention_limit
  snapshot_window          = "02:00-03:00"
  maintenance_window       = "sun:05:00-sun:06:00"
  apply_immediately        = true
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-cache"
  })
}