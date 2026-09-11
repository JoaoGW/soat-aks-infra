data "azurerm_resource_group" "platform" {
  name = var.platform_resource_group_name
}

data "azurerm_resource_group" "data" {
  name = var.data_resource_group_name
}

data "azurerm_resource_group" "auth" {
  name = var.auth_resource_group_name
}

data "azurerm_storage_account" "state" {
  name                = var.state_storage_account_name
  resource_group_name = var.state_resource_group_name
}

locals {
  name_prefix = "soat-${var.resource_name_suffix}"

  github_identities = {
    aks_plan = {
      repository = "soat-aks-infra"
      subject    = "repo:JoaoGW@68306736/soat-aks-infra@1362779510:pull_request"
      role       = "Reader"
      purpose    = "plan"
    }
    aks_hml = {
      repository = "soat-aks-infra"
      subject    = "repo:JoaoGW@68306736/soat-aks-infra@1362779510:environment:hml"
      role       = "Contributor"
      purpose    = "deploy"
    }
    aks_prod = {
      repository = "soat-aks-infra"
      subject    = "repo:JoaoGW@68306736/soat-aks-infra@1362779510:environment:prod"
      role       = "Contributor"
      purpose    = "deploy"
    }
    aks_observability = {
      repository = "soat-aks-infra"
      subject    = "repo:JoaoGW@68306736/soat-aks-infra@1362779510:environment:observability"
      role       = "Reader"
      purpose    = "deploy"
    }
    postgres_plan = {
      repository = "soat-postgres-infra"
      subject    = "repo:JoaoGW@68306736/soat-postgres-infra@1362779564:pull_request"
      role       = "Reader"
      purpose    = "plan"
    }
    postgres_hml = {
      repository = "soat-postgres-infra"
      subject    = "repo:JoaoGW@68306736/soat-postgres-infra@1362779564:environment:hml"
      role       = "Contributor"
      purpose    = "deploy"
    }
    postgres_prod = {
      repository = "soat-postgres-infra"
      subject    = "repo:JoaoGW@68306736/soat-postgres-infra@1362779564:environment:prod"
      role       = "Contributor"
      purpose    = "deploy"
    }
    auth_plan = {
      repository = "soat-auth-function"
      subject    = "repo:JoaoGW@68306736/soat-auth-function@1362779433:pull_request"
      role       = "Reader"
      purpose    = "plan"
    }
    auth_hml = {
      repository = "soat-auth-function"
      subject    = "repo:JoaoGW@68306736/soat-auth-function@1362779433:environment:hml"
      role       = "Contributor"
      purpose    = "deploy"
    }
    auth_prod = {
      repository = "soat-auth-function"
      subject    = "repo:JoaoGW@68306736/soat-auth-function@1362779433:environment:prod"
      role       = "Contributor"
      purpose    = "deploy"
    }
    api_plan = {
      repository = "soat-api"
      subject    = "repo:JoaoGW@68306736/soat-api@1362779355:pull_request"
      role       = "Reader"
      purpose    = "plan"
    }
    api_hml = {
      repository = "soat-api"
      subject    = "repo:JoaoGW@68306736/soat-api@1362779355:environment:hml"
      role       = "Reader"
      purpose    = "deploy"
    }
    api_prod = {
      repository = "soat-api"
      subject    = "repo:JoaoGW@68306736/soat-api@1362779355:environment:prod"
      role       = "Reader"
      purpose    = "deploy"
    }
  }
}

resource "azurerm_virtual_network" "platform" {
  name                = "vnet-${local.name_prefix}"
  address_space       = ["10.30.0.0/16"]
  location            = var.location
  resource_group_name = data.azurerm_resource_group.platform.name
}

resource "azurerm_subnet" "aks" {
  name                 = "snet-aks"
  resource_group_name  = data.azurerm_resource_group.platform.name
  virtual_network_name = azurerm_virtual_network.platform.name
  address_prefixes     = ["10.30.0.0/22"]
}

resource "azurerm_subnet" "postgresql" {
  name                 = "snet-postgresql"
  resource_group_name  = data.azurerm_resource_group.platform.name
  virtual_network_name = azurerm_virtual_network.platform.name
  address_prefixes     = ["10.30.4.0/24"]

  delegation {
    name = "postgresql-flexible-server"

    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

resource "azurerm_subnet" "function" {
  name                 = "snet-function"
  resource_group_name  = data.azurerm_resource_group.platform.name
  virtual_network_name = azurerm_virtual_network.platform.name
  address_prefixes     = ["10.30.5.0/24"]

  delegation {
    name = "function-vnet-integration"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_private_dns_zone" "postgresql" {
  name                = "${local.name_prefix}.postgres.database.azure.com"
  resource_group_name = data.azurerm_resource_group.platform.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgresql" {
  name                  = "${local.name_prefix}-postgresql"
  resource_group_name   = data.azurerm_resource_group.platform.name
  private_dns_zone_name = azurerm_private_dns_zone.postgresql.name
  virtual_network_id    = azurerm_virtual_network.platform.id
}

resource "azurerm_key_vault" "platform" {
  name                          = "kv${replace(local.name_prefix, "-", "")}"
  location                      = data.azurerm_resource_group.platform.location
  resource_group_name           = data.azurerm_resource_group.platform.name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  soft_delete_retention_days    = 7
  purge_protection_enabled      = true
  rbac_authorization_enabled    = true
  public_network_access_enabled = true
}

data "azurerm_client_config" "current" {}

resource "azurerm_kubernetes_cluster" "shared" {
  name                = "aks-${local.name_prefix}"
  location            = data.azurerm_resource_group.platform.location
  resource_group_name = data.azurerm_resource_group.platform.name
  dns_prefix          = "aks-${local.name_prefix}"
  sku_tier            = "Free"

  default_node_pool {
    name                 = "system"
    vm_size              = var.node_vm_size
    vnet_subnet_id       = azurerm_subnet.aks.id
    auto_scaling_enabled = true
    min_count            = 1
    max_count            = 2
    type                 = "VirtualMachineScaleSets"
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "azure"
    service_cidr        = "10.31.0.0/16"
    dns_service_ip      = "10.31.0.10"
  }

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled = true
    tenant_id          = data.azurerm_client_config.current.tenant_id
  }

  oidc_issuer_enabled       = true
  workload_identity_enabled = true
  local_account_disabled    = true
  azure_policy_enabled      = true

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  lifecycle {
    ignore_changes = [default_node_pool[0].upgrade_settings]
  }
}

resource "azurerm_user_assigned_identity" "github" {
  for_each            = local.github_identities
  name                = "uami-${local.name_prefix}-${replace(each.key, "_", "-")}"
  location            = data.azurerm_resource_group.platform.location
  resource_group_name = data.azurerm_resource_group.platform.name
}

resource "azurerm_federated_identity_credential" "github" {
  for_each                  = local.github_identities
  name                      = "github-${replace(each.key, "_", "-")}"
  user_assigned_identity_id = azurerm_user_assigned_identity.github[each.key].id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = "https://token.actions.githubusercontent.com"
  subject                   = each.value.subject
}

resource "azurerm_role_assignment" "github_platform" {
  for_each             = local.github_identities
  scope                = data.azurerm_resource_group.platform.id
  role_definition_name = startswith(each.key, "postgres_") || startswith(each.key, "auth_") ? "Reader" : each.value.role
  principal_id         = azurerm_user_assigned_identity.github[each.key].principal_id
}

resource "azurerm_role_assignment" "github_data" {
  for_each = {
    for key, identity in local.github_identities : key => identity
    if startswith(key, "postgres_") || identity.purpose == "plan"
  }

  scope                = data.azurerm_resource_group.data.id
  role_definition_name = startswith(each.key, "postgres_") ? each.value.role : "Reader"
  principal_id         = azurerm_user_assigned_identity.github[each.key].principal_id
}

resource "azurerm_role_assignment" "github_auth" {
  for_each = {
    for key, identity in local.github_identities : key => identity
    if startswith(key, "auth_") || identity.purpose == "plan"
  }

  scope                = data.azurerm_resource_group.auth.id
  role_definition_name = startswith(each.key, "auth_") ? each.value.role : "Reader"
  principal_id         = azurerm_user_assigned_identity.github[each.key].principal_id
}

resource "azurerm_role_assignment" "github_state" {
  for_each = local.github_identities

  scope                = data.azurerm_storage_account.state.id
  role_definition_name = each.value.purpose == "plan" ? "Storage Blob Data Reader" : "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.github[each.key].principal_id
}

resource "azurerm_role_assignment" "postgresql_subnet" {
  for_each = {
    for key, identity in local.github_identities : key => identity
    if identity.purpose == "deploy" && startswith(key, "postgres_")
  }

  scope                = azurerm_subnet.postgresql.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.github[each.key].principal_id
}

resource "azurerm_role_assignment" "postgresql_key_vault" {
  for_each = {
    for key, identity in local.github_identities : key => identity
    if identity.purpose == "deploy" && startswith(key, "postgres_")
  }

  scope                = azurerm_key_vault.platform.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = azurerm_user_assigned_identity.github[each.key].principal_id
}

resource "azurerm_role_assignment" "auth_function_subnet" {
  for_each = {
    for key, identity in local.github_identities : key => identity
    if identity.purpose == "deploy" && startswith(key, "auth_")
  }

  scope                = azurerm_subnet.function.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.github[each.key].principal_id
}

resource "azurerm_role_assignment" "auth_key_vault" {
  for_each = {
    for key, identity in local.github_identities : key => identity
    if identity.purpose == "deploy" && startswith(key, "auth_")
  }

  scope                = azurerm_key_vault.platform.id
  role_definition_name = "Key Vault Data Access Administrator"
  principal_id         = azurerm_user_assigned_identity.github[each.key].principal_id
}

resource "azurerm_role_assignment" "aks_cluster_admin" {
  for_each = {
    for key, identity in local.github_identities : key => identity
    if identity.purpose == "deploy" && (startswith(key, "aks_") || startswith(key, "api_"))
  }

  scope                = azurerm_kubernetes_cluster.shared.id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = azurerm_user_assigned_identity.github[each.key].principal_id
}

resource "azurerm_role_assignment" "api_cluster_user" {
  for_each = {
    for key, identity in local.github_identities : key => identity
    if identity.purpose == "deploy" && (startswith(key, "aks_") || startswith(key, "api_"))
  }

  scope                = azurerm_kubernetes_cluster.shared.id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  principal_id         = azurerm_user_assigned_identity.github[each.key].principal_id
}

resource "azurerm_role_assignment" "aks_plan_cluster_user" {
  scope                = azurerm_kubernetes_cluster.shared.id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  principal_id         = azurerm_user_assigned_identity.github["aks_plan"].principal_id
}

resource "azurerm_role_assignment" "aks_plan_cluster_reader" {
  scope                = azurerm_kubernetes_cluster.shared.id
  role_definition_name = "Azure Kubernetes Service RBAC Reader"
  principal_id         = azurerm_user_assigned_identity.github["aks_plan"].principal_id
}

resource "azurerm_user_assigned_identity" "api_workload" {
  for_each            = toset(["hml", "prod"])
  name                = "uami-${local.name_prefix}-api-workload-${each.key}"
  location            = data.azurerm_resource_group.platform.location
  resource_group_name = data.azurerm_resource_group.platform.name
}

resource "azurerm_federated_identity_credential" "api_workload" {
  for_each                  = toset(["hml", "prod"])
  name                      = "aks-api-${each.key}"
  user_assigned_identity_id = azurerm_user_assigned_identity.api_workload[each.key].id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = azurerm_kubernetes_cluster.shared.oidc_issuer_url
  subject                   = "system:serviceaccount:${each.key}:soat-api"
}

resource "azurerm_role_assignment" "api_key_vault" {
  for_each             = toset(["hml", "prod"])
  scope                = azurerm_key_vault.platform.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.api_workload[each.key].principal_id
}

resource "azurerm_user_assigned_identity" "observability_workload" {
  name                = "uami-${local.name_prefix}-observability"
  location            = data.azurerm_resource_group.platform.location
  resource_group_name = data.azurerm_resource_group.platform.name
}

resource "azurerm_federated_identity_credential" "observability_workload" {
  name                      = "aks-observability"
  user_assigned_identity_id = azurerm_user_assigned_identity.observability_workload.id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = azurerm_kubernetes_cluster.shared.oidc_issuer_url
  subject                   = "system:serviceaccount:observability:newrelic-keyvault-sync"
}

resource "azurerm_role_assignment" "observability_key_vault" {
  scope                = azurerm_key_vault.platform.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.observability_workload.principal_id
}

resource "azurerm_user_assigned_identity" "auth_function_workload" {
  for_each            = toset(["hml", "prod"])
  name                = "uami-${local.name_prefix}-auth-function-${each.key}"
  location            = data.azurerm_resource_group.platform.location
  resource_group_name = data.azurerm_resource_group.platform.name
}

resource "azurerm_role_assignment" "auth_function_key_vault" {
  for_each             = toset(["hml", "prod"])
  scope                = azurerm_key_vault.platform.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.auth_function_workload[each.key].principal_id
}
