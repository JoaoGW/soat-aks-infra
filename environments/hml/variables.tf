variable "state_resource_group_name" {
  type = string
}

variable "resource_name_suffix" {
  description = "Sufixo da Function hml. Sem valor, a rota do Kong não é criada."
  type        = string
  default     = ""
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

variable "kong_crds_ready" {
  description = "Habilita plugins Kong depois que o primeiro deploy do chart registrar seus CRDs no cluster."
  type        = bool
  default     = false
}

variable "aks_server_application_id" {
  description = "ID público do servidor Microsoft Entra usado pelo kubelogin para AKS."
  type        = string
  default     = "6dae42f8-4368-4678-94ff-3960e28e3630"
}
