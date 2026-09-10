variable "state_resource_group_name" { type = string }
variable "state_storage_account_name" { type = string }
variable "aks_state_container_name" { type = string }
variable "aks_server_application_id" {
  type    = string
  default = "6dae42f8-4368-4678-94ff-3960e28e3630"
}
variable "newrelic_chart_version" {
  description = "Versão fixada do chart nr-k8s-otel-collector."
  type        = string
  default     = "0.14.1"
}
