locals {
  func_name = "weatherplugin"
}

resource "azurerm_storage_account" "sa" {
  name                      = "stfunc${local.func_name}"
  location                  = azurerm_resource_group.rg.location
  resource_group_name       = azurerm_resource_group.rg.name
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  enable_https_traffic_only = true
}

resource "azapi_resource" "ca_function" {
  schema_validation_enabled = false
  name                      = "func-${local.func_name}"
  location                  = azurerm_resource_group.rg.location
  parent_id                 = azurerm_resource_group.rg.id
  type                      = "Microsoft.Web/sites@2023-01-01"
  body = jsonencode({
    kind = "functionapp,linux,container,azurecontainerapps"
    properties : {
      language             = "dotnet-isolated"
      managedEnvironmentId = azapi_resource.cae.id
      siteConfig = {
        linuxFxVersion = "DOCKER|${var.weather_plugin_image}"
        appSettings = [
          {
            name  = "AzureWebJobsStorage"
            value = azurerm_storage_account.sa.primary_connection_string
          },
          {
            name  = "WEBSITE_CONTENTAZUREFILECONNECTIONSTRING"
            value = azurerm_storage_account.sa.primary_connection_string
          },
          {
            name  = "APPINSIGHTS_INSTRUMENTATIONKEY"
            value = azurerm_application_insights.appinsights.instrumentation_key
          },
          {
            name  = "APPLICATIONINSIGHTS_CONNECTION_STRING"
            value = "InstrumentationKey=${azurerm_application_insights.appinsights.instrumentation_key}"
          },
          {
            name  = "FUNCTIONS_WORKER_RUNTIME"
            value = "dotnet-isolated"
          },
          {
            name  = "FUNCTIONS_EXTENSION_VERSION"
            value = "~4"
          },
          {
            name  = "MODEL_ID"
            value = "gpt-35-turbo"
          },
          {
            name  = "API_KEY"
            value = "${azurerm_cognitive_account.openai.primary_access_key}"
          },
          {
            name  = "ENDPOINT"
            value = "${azurerm_cognitive_account.openai.endpoint}"
          },
          {
            name  = "OpenApi__HostNames"
            value = "https://func-${local.func_name}.${azapi_resource.cae.output.properties.defaultDomain}/api"
          }
        ]
      }
      workloadProfileName = "Consumption"
      resourceConfig = {
        cpu    = 1
        memory = "2Gi"
      }
      httpsOnly = false
    }
  })
}
