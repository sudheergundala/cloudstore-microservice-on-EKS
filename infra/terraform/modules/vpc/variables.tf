variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a vaild cidr block"
  }
}

variable "name_prefix" {
  description = "prefix for naming all the resources(ex: cloudstore-dev)"
  type        = string
}

variable "availability_zones" {
  description = "list of AZs to spread subnets accross"
  type        = list(string)
}

variable "cluster_name" {
  description = "EKS cluster name (used for subnet tags so eks can discover them) "
  type        = string
}

variable "tags" {
  description = "tags applied to all resources"
  type        = map(string)
  default     = {}
}

