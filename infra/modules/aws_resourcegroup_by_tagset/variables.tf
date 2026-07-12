###############################################################################
# Variables
#

variable "resource_group_name" {
  description = "Name to apply to the resource group."
  type        = string
  sensitive   = false
}

variable "resource_group_description" {
  description = "Description to apply to the resource group."
  type        = string
  sensitive   = false
  default     = null
}

variable "common_tags" {
  description = "Map of common tags (applied to all AWS infrastrucure), used to group resources."
  type        = map(string)
  sensitive   = false
}
