resource "azapi_resource" "sk_minimal_api" {
  depends_on = [azurerm_container_registry_task.sk_api_acr_task]
  name       = "sk-minimal-api"
  location   = azurerm_resource_group.rg.location
  parent_id  = azurerm_resource_group.rg.id
  type       = "Microsoft.App/containerApps@2022-11-01-preview"
  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.mi.id
    ]
  }

  body = jsonencode({
    properties : {
      managedEnvironmentId = "${azapi_resource.cae.id}"
      configuration = {
        registries = [
          {
            server            = "${azurerm_container_registry.acr.login_server}"
            username          = "${azurerm_container_registry.acr.admin_username}"
            passwordSecretRef = "acrpassword"
          }
        ]
        secrets = [
          {
            name  = "azureopenaiapikey"
            value = "${var.azure_openai_api_key}"
          },
          {
            name  = "openaikey"
            value = "${var.openai_key}"
          },
          {
            name  = "acrpassword"
            value = "${azurerm_container_registry.acr.admin_password}"
          }
        ]
        ingress = {
          "corsPolicy" = {
            allowedOrigins = ["*"]
            allowedHeaders = ["*"]
            allowedMethods = ["*"]
            exposeHeaders  = ["*"]
          }
          external   = true
          targetPort = 8080
          transport  = "Http"
        }
      }
      template = {
        containers = [
          {
            name  = "api"
            image = "${azurerm_container_registry.acr.login_server}/sk-minimal-api:1.9"
            resources = {
              cpu    = 2
              memory = "4Gi"
            }
            env = [
              {
                name  = "model"
                value = "gpt-4"
              },
              {
                name      = "apiKey"
                secretRef = "azureopenaiapikey"
              },
              {
                name  = "endpoint"
                value = "https://semantic-kernel-models.openai.azure.com/"
              },
              {
                name      = "openaiKey"
                secretRef = "openaikey"
              },
              {
                name  = "qdrant"
                value = "https://${jsondecode(azapi_resource.qdrant.output).properties.configuration.ingress.fqdn}"
              }
            ],
          },
        ]
        scale = {
          minReplicas = 1
          maxReplicas = 1
        }
      }
    }
  })

  response_export_values = ["properties.configuration.ingress.fqdn"]
}
