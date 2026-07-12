variable "name_prefix" {
  description = "prefix for all the resources"
  type        = string
}

variable "private_subnet_ids" {
  description = "private subnet IDs for each cache subnet group"
  type        = list(string)
}

variable "elasticache_security_group_id" {
  description = "security group id for the cache"
  type        = string
}

variable "node_type" {
  description = "cache node instance type"
  type        = string
  default     = "cache.t3.micro"
}

variable "engine_version" {
  description = "valkey engine version"
  type        = string
  default     = "8.0"
}

variable "num_cache_cluster" {
  description = "Number of node(1 primary + N-1 replicas)"
  type        = number
  default     = 2
}
variable "multi_az" {
  description = "Enable multi_az(requires num_cache_cluster >= 2)"
  type        = bool
  default     = true
}

variable "snapshot_retention_limit" {
  description = "days to retain cache snapshots(0 disables)"
  type        = number
  default     = 1
}

variable "automatic_failover" {
  description = "Auto-promote a replica if primary fails (requires 2+ nodes)"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to all the resources"
  type        = map(string)
  default     = {}
}