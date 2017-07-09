variable "name" {
  description = "The name prefix to use for resources."
}

variable "env" {
  description = "The environment name"
}

variable "readonly_accounts" {
  description = "List of account IDs to trust root from"
  type        = "list"
  default     = []
}

variable "readonly_roles" {
  description = "List of role ARNs to trust"
  type        = "list"
  default     = []
}

variable "readwrite_accounts" {
  description = "List of account IDs to trust root from"
  type        = "list"
  default     = []
}

variable "readwrite_roles" {
  description = "List of role ARNs to trust"
  type        = "list"
  default     = []
}