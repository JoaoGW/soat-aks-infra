variable "location" {
  description = "Região Azure previamente validada para os grupos de recursos."
  type        = string
  default     = "brazilsouth"
}

variable "platform_resource_group_name" {
  description = "Grupo de recursos da plataforma criado na Fase 0."
  type        = string
  default     = "rg-soat-platform"
}

variable "data_resource_group_name" {
  description = "Grupo de recursos de dados criado na Fase 0."
  type        = string
  default     = "rg-soat-data"
}

variable "auth_resource_group_name" {
  description = "Grupo de recursos de autenticação criado na Fase 0."
  type        = string
  default     = "rg-soat-auth"
}

variable "resource_name_suffix" {
  description = "Sufixo globalmente único, em minúsculas, para Key Vault e AKS."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,12}$", var.resource_name_suffix))
    error_message = "resource_name_suffix deve ter de 3 a 12 caracteres alfanuméricos minúsculos."
  }
}

variable "state_resource_group_name" {
  description = "Grupo de recursos da Storage Account de state criada na Fase 0."
  type        = string
}

variable "state_storage_account_name" {
  description = "Nome da Storage Account privada de state criada na Fase 0."
  type        = string
}

variable "node_vm_size" {
  description = "SKU validado no pré-flight. Não há fallback automático."
  type        = string
  default     = "Standard_D2as_v6"
}
