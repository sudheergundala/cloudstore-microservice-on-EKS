variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "name_prefix" {
  description = ""
  type        = string
}

variable "aws_region" {
  description = ""
  type        = string
}

variable "private_route_table_ids" {
  description = ""
  type        = list(string)
}

variable "tags" {
  description = ""
  type        = map(string)
  default     = {}
}