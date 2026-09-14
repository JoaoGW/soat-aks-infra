variable "namespace" {
  type = string
}

variable "create_shared_namespaces" {
  type    = bool
  default = false
}

variable "install_kong" {
  type    = bool
  default = false
}

variable "kong_chart_version" {
  type = string
}
