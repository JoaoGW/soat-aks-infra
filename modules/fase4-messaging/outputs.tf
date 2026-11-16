output "namespace_id" { value = azurerm_servicebus_namespace.this.id }
output "namespace_fqdn" { value = "${azurerm_servicebus_namespace.this.name}.servicebus.windows.net" }
output "workload_client_ids" {
  value = { for key, identity in azurerm_user_assigned_identity.workload : key => identity.client_id }
}
output "workload_principal_ids" {
  value = { for key, identity in azurerm_user_assigned_identity.workload : key => identity.principal_id }
}
