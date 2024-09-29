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

// The identity requires both the Azure Container Apps Session Executor and Contributor roles
resource "azurerm_role_assignment" "session_executor" {
  scope                = azapi_resource.code_interpreter.id
  role_definition_name = "Azure ContainerApps Session Executor"
  principal_id         = azurerm_user_assigned_identity.mi.principal_id
}

// The identity requires both the Azure Container Apps Session Executor and Contributor roles
resource "azurerm_role_assignment" "session_contributor" {
  scope                = azapi_resource.code_interpreter.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.mi.principal_id
}
