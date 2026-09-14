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
  source             = "../../modules/namespace"
  namespace          = "prod"
  install_kong       = false
  kong_chart_version = "3.4.1"
}
