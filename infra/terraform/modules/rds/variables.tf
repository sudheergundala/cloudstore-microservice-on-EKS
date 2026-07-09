variable "name_prefix" {
  description = "Prefix for naming resources"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the DB subnet group"
  type        = list(string)
}

variable "rds_security_group_id" {
  description = "Security group ID for the RDS instance (from SG module)"
  type        = string
}

variable "db_name" {
  description = "Name of the initial database"
  type        = string
  default     = "order"
}

variable "db_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "16.4"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "initial storage in GB"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "maximum storage for autoscalling in GB"
  type        = number
  default     = 100
}

variable "multi_az" {
  description = "Enable multi-AZs for HA. True for Prod and false for dev(cost)"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Days to retain automated backups (enables PITR)"
  type        = number
  default     = 1
}

variable "deletion_protection" {
  description = "Prevent accidental deletion. True for prod"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on destroy. true for dev, false for prod"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}