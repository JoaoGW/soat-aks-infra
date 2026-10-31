resource "azurerm_servicebus_namespace" "this" {
  name                          = var.namespace_name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  sku                           = "Standard"
  local_auth_enabled            = false
  minimum_tls_version           = "1.2"
  public_network_access_enabled = true
}

resource "azurerm_servicebus_queue" "commands" {
  for_each     = toset(["billing", "execution"])
  name         = "${each.key}.commands"
  namespace_id = azurerm_servicebus_namespace.this.id

  max_delivery_count                   = 10
  dead_lettering_on_message_expiration = true
}

resource "azurerm_servicebus_topic" "events" {
  name         = "soat.domain.events"
  namespace_id = azurerm_servicebus_namespace.this.id
}

resource "azurerm_servicebus_subscription" "os" {
  name               = "os.saga-events"
  topic_id           = azurerm_servicebus_topic.events.id
  max_delivery_count = 10
}

resource "azurerm_user_assigned_identity" "workload" {
  for_each            = toset(["os", "billing", "execution"])
  name                = "uami-soat-${var.name_suffix}-${each.key}-fase4-hml"
  resource_group_name = var.resource_group_name
  location            = var.location
}

resource "azurerm_federated_identity_credential" "workload" {
  for_each                  = azurerm_user_assigned_identity.workload
  name                      = "soat-${each.key}-hml"
  resource_group_name       = var.resource_group_name
  user_assigned_identity_id = each.value.id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = var.aks_oidc_issuer_url
  subject                   = "system:serviceaccount:hml:soat-${each.key}-service"
}

resource "azurerm_role_assignment" "event_send" {
  for_each             = azurerm_user_assigned_identity.workload
  scope                = azurerm_servicebus_topic.events.id
  role_definition_name = "Azure Service Bus Data Sender"
  principal_id         = each.value.principal_id
}

resource "azurerm_role_assignment" "command_send" {
  for_each             = azurerm_servicebus_queue.commands
  scope                = each.value.id
  role_definition_name = "Azure Service Bus Data Sender"
  principal_id         = azurerm_user_assigned_identity.workload["os"].principal_id
}

resource "azurerm_role_assignment" "command_receive" {
  for_each             = azurerm_servicebus_queue.commands
  scope                = each.value.id
  role_definition_name = "Azure Service Bus Data Receiver"
  principal_id         = azurerm_user_assigned_identity.workload[each.key].principal_id
}

resource "azurerm_role_assignment" "event_receive" {
  scope                = azurerm_servicebus_subscription.os.id
  role_definition_name = "Azure Service Bus Data Receiver"
  principal_id         = azurerm_user_assigned_identity.workload["os"].principal_id
}
