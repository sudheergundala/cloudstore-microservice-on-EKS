variable "name_prefix" {
  description = "Prefix for naming resources"
  type        = string
}

variable "billing_mode" {
  description = "PAY_PER_REQUEST(on demand) or PROVISIONED"
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "tags" {
  description = "Tags applies to all the resources"
  type        = map(string)
  default     = {}
}

variable "enable_streams" {
  description = "Enable DynamoDB streams(for the search-sync Lambda/CDC)"
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Prevent accidental table deletion (true for production)"
  type        = bool
  default     = false
}