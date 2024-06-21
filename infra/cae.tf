resource "azapi_resource" "cae" {
  name      = local.cae_name
  location  = azurerm_resource_group.rg.location
  parent_id = azurerm_resource_group.rg.id
  type      = "Microsoft.App/managedEnvironments@2022-11-01-preview"

  body = {
    properties : {
      daprAIInstrumentationKey = "${azurerm_application_insights.appinsights.instrumentation_key}"
      appLogsConfiguration = {
        destination = "log-analytics"
        logAnalyticsConfiguration = {
          customerId = "${azurerm_log_analytics_workspace.logs.workspace_id}"
          sharedKey  = "${azurerm_log_analytics_workspace.logs.primary_shared_key}"
        }
      }
      vnetConfiguration = {
        internal               = false
        infrastructureSubnetId = "${azurerm_subnet.apps.id}"
      }
      workloadProfiles = [
        {
          workloadProfileType = "Consumption"
          name                = "Consumption"
        }
      ]
    }
  }
  response_export_values = ["properties.defaultDomain"]
}
