variable "state_resource_group_name" {
  type = string
}

variable "state_storage_account_name" {
  type = string
}

variable "aks_state_container_name" {
  type = string
}

variable "kong_chart_version" {
  type    = string
  default = "2.53.0"
}

variable "aks_server_application_id" {
  description = "ID público do servidor Microsoft Entra usado pelo kubelogin para AKS."
  type        = string
  default     = "6dae42f8-4368-4678-94ff-3960e28e3630"
}
