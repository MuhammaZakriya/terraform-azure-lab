data "azurerm_subscription" "current" {}

resource "azurerm_role_assignment" "contributor" {
  scope                = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${var.resource_group_name}"
  role_definition_name = "Contributor"
  principal_id         = var.principal_id
}
