variable "kube_config_path" {
  description = "Path to the Kubernetes configuration file on the Bastion"
  type        = string
  default     = "~/.kube/config"
}

variable "environments" {
  description = "List of namespaces to provision for our platform"
  type        = list(string)
  default     = ["staging", "production"]
}

variable "cpu_quota_limit" {
  description = "Maximum CPU cores allowed per namespace"
  type        = string
  default     = "4"
}

variable "memory_quota_limit" {
  description = "Maximum memory allowed per namespace"
  type        = string
  default     = "4Gi"
}