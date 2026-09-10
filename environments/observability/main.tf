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
    args        = ["get-token", "--login", "azurecli", "--server-id", var.aks_server_application_id]
  }
}

provider "helm" {
  kubernetes {
    host                   = data.terraform_remote_state.foundation.outputs.aks_host
    cluster_ca_certificate = base64decode(data.terraform_remote_state.foundation.outputs.aks_cluster_ca_certificate)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "kubelogin"
      args        = ["get-token", "--login", "azurecli", "--server-id", var.aks_server_application_id]
    }
  }
}

resource "kubernetes_service_account_v1" "keyvault_sync" {
  metadata {
    name        = "newrelic-keyvault-sync"
    namespace   = "observability"
    annotations = { "azure.workload.identity/client-id" = data.terraform_remote_state.foundation.outputs.observability_workload_client_id }
    labels      = { "azure.workload.identity/use" = "true" }
  }
}

resource "kubernetes_manifest" "newrelic_license" {
  count = var.secrets_store_crds_ready ? 1 : 0

  manifest = {
    apiVersion = "secrets-store.csi.x-k8s.io/v1"
    kind       = "SecretProviderClass"
    metadata   = { name = "newrelic-license", namespace = "observability" }
    spec = {
      provider      = "azure"
      secretObjects = [{ secretName = "newrelic-license", type = "Opaque", data = [{ objectName = "new-relic-license-key", key = "licenseKey" }] }]
      parameters = {
        usePodIdentity       = "false"
        useVMManagedIdentity = "false"
        clientID             = data.terraform_remote_state.foundation.outputs.observability_workload_client_id
        keyvaultName         = data.terraform_remote_state.foundation.outputs.key_vault_name
        tenantId             = data.terraform_remote_state.foundation.outputs.tenant_id
        objects              = "array:\n  - |\n    objectName: new-relic-license-key\n    objectType: secret"
      }
    }
  }
}

resource "kubernetes_deployment_v1" "keyvault_sync" {
  metadata {
    name      = "newrelic-keyvault-sync"
    namespace = "observability"
  }
  spec {
    replicas = 1
    selector { match_labels = { app = "newrelic-keyvault-sync" } }
    template {
      metadata { labels = { app = "newrelic-keyvault-sync", "azure.workload.identity/use" = "true" } }
      spec {
        service_account_name = kubernetes_service_account_v1.keyvault_sync.metadata[0].name
        container {
          name    = "sync"
          image   = "mcr.microsoft.com/oss/busybox/busybox:1.36.1"
          command = ["sh", "-c", "sleep 365d"]
          volume_mount {
            name       = "secrets"
            mount_path = "/mnt/secrets-store"
            read_only  = true
          }
        }
        volume {
          name = "secrets"
          csi {
            driver            = "secrets-store.csi.k8s.io"
            read_only         = true
            volume_attributes = { secretProviderClass = "newrelic-license" }
          }
        }
      }
    }
  }
  depends_on = [kubernetes_manifest.newrelic_license]
}

resource "helm_release" "newrelic" {
  name       = "nr-k8s-otel-collector"
  repository = "https://helm-charts.newrelic.com"
  chart      = "nr-k8s-otel-collector"
  version    = var.newrelic_chart_version
  namespace  = "observability"
  wait       = true
  set {
    name  = "global.cluster"
    value = data.terraform_remote_state.foundation.outputs.aks_name
  }
  set {
    name  = "global.customSecretName"
    value = "newrelic-license"
  }
  set {
    name  = "global.customSecretLicenseKey"
    value = "licenseKey"
  }
  set {
    name  = "receivers.filelog.enabled"
    value = "false"
  }
  depends_on = [kubernetes_deployment_v1.keyvault_sync]
}
