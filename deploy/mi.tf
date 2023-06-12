# Create Managed Identity
resource "azurerm_user_assigned_identity" "mi" {
  name                = var.managed_identity_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

# Assign the Reader role to the Managed Identity
resource "azurerm_role_assignment" "reader" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.mi.principal_id
}
