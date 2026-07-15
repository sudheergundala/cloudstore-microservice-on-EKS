variable "name_prefix" {
  description = "prefix for naming resources"
  type        = string
}

variable "tags" {
  description = "Tags for all the resources"
  type        = map(string)
  default     = {}
}

variable "account_id" {
  description = "Account ID for globally unique bucket name"
  type        = string
}

variable "force_destroy" {
  description = "Allow destroying non-empty bucket(True for dev, flase for prod)"
  type        = bool
  default     = true
}