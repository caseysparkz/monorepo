/* Variables */

variable "docker_socket" {
  description = "Unix path to the docker socket."
  type        = string
  sensitive   = false
  default     = "unix:///var/run/docker.sock"
}
