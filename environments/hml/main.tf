data "terraform_remote_state" "foundation" {
  backend = "azurerm"

  config = {
    resource_group_name  = var.state_resource_group_name
    storage_account_name = var.state_storage_account_name
    container_name       = var.aks_state_container_name
    key                  = "foundation.tfstate"
    use_azuread_auth     = true
  }
}

provider "kubernetes" {
  host                   = data.terraform_remote_state.foundation.outputs.aks_host
  cluster_ca_certificate = base64decode(data.terraform_remote_state.foundation.outputs.aks_cluster_ca_certificate)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "kubelogin"
    args = [
      "get-token",
      "--login",
      "azurecli",
      "--server-id",
      var.aks_server_application_id,
    ]
  }
}

provider "helm" {
  kubernetes {
    host                   = data.terraform_remote_state.foundation.outputs.aks_host
    cluster_ca_certificate = base64decode(data.terraform_remote_state.foundation.outputs.aks_cluster_ca_certificate)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "kubelogin"
      args = [
        "get-token",
        "--login",
        "azurecli",
        "--server-id",
        var.aks_server_application_id,
      ]
    }
  }
}

module "namespace" {
  source                   = "../../modules/namespace"
  namespace                = "hml"
  create_shared_namespaces = true
  install_kong             = true
  kong_chart_version       = var.kong_chart_version
}

resource "kubernetes_manifest" "correlation_id" {
  manifest = {
    apiVersion = "configuration.konghq.com/v1"
    kind       = "KongClusterPlugin"
    metadata = {
      name        = "correlation-id"
      labels      = { global = "true" }
      annotations = { "kubernetes.io/ingress.class" = "kong" }
    }
    plugin = "correlation-id"
    config = {
      header_name     = "X-Correlation-ID"
      generator       = "uuid#counter"
      echo_downstream = true
    }
  }
  depends_on = [module.namespace]
}

locals {
  auth_function_hostname = "func-soat-auth-hml-${var.resource_name_suffix}.azurewebsites.net"
}

resource "kubernetes_manifest" "auth_cpf_rate_limit" {
  count = var.resource_name_suffix == "" ? 0 : 1

  manifest = {
    apiVersion = "configuration.konghq.com/v1"
    kind       = "KongPlugin"
    metadata = {
      name      = "auth-cpf-rate-limit"
      namespace = "kong"
    }
    plugin = "rate-limiting"
    config = {
      limit_by = "ip"
      minute   = 5
      policy   = "local"
    }
  }

  depends_on = [module.namespace]
}

resource "kubernetes_service_v1" "auth_function" {
  count = var.resource_name_suffix == "" ? 0 : 1

  metadata {
    name      = "soat-auth-function"
    namespace = "kong"
    annotations = {
      "konghq.com/protocol" = "https"
    }
  }

  spec {
    type          = "ExternalName"
    external_name = local.auth_function_hostname

    port {
      name        = "https"
      port        = 443
      target_port = 443
    }
  }

  depends_on = [module.namespace]
}

resource "kubernetes_ingress_v1" "auth_cpf" {
  count = var.resource_name_suffix == "" ? 0 : 1

  metadata {
    name      = "auth-cpf"
    namespace = "kong"
    annotations = {
      "konghq.com/plugins"    = "auth-cpf-rate-limit"
      "konghq.com/strip-path" = "false"
    }
  }

  spec {
    ingress_class_name = "kong"

    rule {
      http {
        path {
          path      = "/auth/cpf"
          path_type = "Exact"

          backend {
            service {
              name = kubernetes_service_v1.auth_function[0].metadata[0].name

              port {
                name = "https"
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_manifest.auth_cpf_rate_limit,
    kubernetes_service_v1.auth_function,
  ]
}
