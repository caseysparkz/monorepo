################################################################################
# Variables
#

# Misc. ========================================================================
variable "root_domain" {
  type        = string
  description = "Root domain of Terraform infrastructure."
  sensitive   = false
  default     = "caseysparkz.com"
}

variable "docker_socket" {
  description = "Unix path to the docker socket."
  type        = string
  sensitive   = false
  default     = "unix:///var/run/docker.sock"
}
