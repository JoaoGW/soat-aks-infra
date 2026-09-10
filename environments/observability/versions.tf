terraform {
  required_version = "~> 1.9.8"
  backend "azurerm" {}
  required_providers {
    kubernetes = { source = "hashicorp/kubernetes", version = "~> 2.36" }
    helm       = { source = "hashicorp/helm", version = "~> 2.16" }
  }
}
