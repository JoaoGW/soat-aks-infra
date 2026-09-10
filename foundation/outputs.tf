output "aks_name" {
  value = azurerm_kubernetes_cluster.shared.name
}

output "aks_host" {
  value = azurerm_kubernetes_cluster.shared.kube_config[0].host
}

output "aks_cluster_ca_certificate" {
  value     = azurerm_kubernetes_cluster.shared.kube_config[0].cluster_ca_certificate
  sensitive = true
}

output "aks_oidc_issuer_url" {
  value = azurerm_kubernetes_cluster.shared.oidc_issuer_url
}

output "platform_resource_group_name" {
  value = data.azurerm_resource_group.platform.name
}

output "data_resource_group_name" {
  value = data.azurerm_resource_group.data.name
}

output "auth_resource_group_name" {
  value = data.azurerm_resource_group.auth.name
}

output "postgresql_subnet_id" {
  value = azurerm_subnet.postgresql.id
}

output "postgresql_private_dns_zone_id" {
  value = azurerm_private_dns_zone.postgresql.id
}

output "key_vault_id" {
  value = azurerm_key_vault.platform.id
}

output "key_vault_name" {
  value = azurerm_key_vault.platform.name
}

output "key_vault_uri" {
  value = azurerm_key_vault.platform.vault_uri
}

output "github_identity_client_ids" {
  value = {
    for key, identity in azurerm_user_assigned_identity.github : key => identity.client_id
  }
}

output "api_workload_client_ids" {
  value = {
    for environment, identity in azurerm_user_assigned_identity.api_workload : environment => identity.client_id
  }
}
