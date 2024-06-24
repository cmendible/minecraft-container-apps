resource "azapi_resource" "minecraft_bot" {
  name      = "minecraft-bot"
  location  = azurerm_resource_group.rg.location
  parent_id = azurerm_resource_group.rg.id
  type      = "Microsoft.App/containerApps@2022-11-01-preview"
  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.mi.id
    ]
  }

  body = {
    properties : {
      managedEnvironmentId = "${azapi_resource.cae.id}"
      configuration = {
        secrets = [
          {
            name  = "azureopenaiapikey"
            value = "${azurerm_cognitive_account.openai.primary_access_key}"
          }
        ]
        ingress = {
          external   = true
          targetPort = 8080
          transport  = "Http"

          traffic = [
            {
              latestRevision = true
              weight         = 100
            }
          ]
        }
        dapr = {
          enabled     = true
          appId       = "minecraft-bot"
          appProtocol = "http"
          appPort     = 80
        }
      }
      template = {
        containers = [
          {
            name  = "minecraft-bot"
            image = var.minecraft_bot_image
            resources = {
              cpu    = 0.5
              memory = "1Gi"
            }
            env = [
              {
                name  = "MINECRAFT_HOST"
                value = "mc-server"
              },
              {
                name  = "MINECRAFT_BOT_NAME"
                value = "Vicky"
              },
              {
                name  = "AZURE_OPENAI_ENDPOINT"
                value = "${azurerm_cognitive_account.openai.endpoint}"
              },
              {
                name  = "AZURE_OPENAI_DEPLOYMENT"
                value = "gpt-35-turbo"
              },
              {
                name      = "AZURE_OPENAI_API_KEY"
                secretRef = "azureopenaiapikey"
              },
              {
                name  = "WEATHER_API_URL"
                value = "https://func-${local.func_name}.${azapi_resource.cae.output.properties.defaultDomain}"
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
  }
}
