variable "location" {
  type = string
}

variable "pim_users" {
  description = "List of PIM user configurations"
  type        = string
}

variable "pim_groups" {
  description = "List of PIM group configurations"
  type        = string
}

variable "management_policies" {
  description = "List of management policy configurations"
  type        = string
}


