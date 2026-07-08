variable "vpc_id" {
  description = "VPC ID where the security groups are created"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for naming resources"
  type        = string
}

variable "app_ports" {
  description = "Ports the application services listens on (from ALB to EKS)"
  type        = list(number)
  default     = [3000, 8000, 8001]
}

variable "tags" {
  description = "tags applied to all resources"
  type        = map(string)
  default     = {}
}
