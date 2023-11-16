resource "azapi_resource" "minecraft_bot" {
  depends_on = [ azurerm_container_registry_task.minecraft_bot_task ]
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
            value = "${azurerm_cognitive_account.openai.primary_access_key}"
          },
          {
            name  = "acrpassword"
            value ="${azurerm_container_registry.acr.admin_password}"
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
          enabled = true
          appId   = "minecraft-bot"
        }
      }
      template = {
        containers = [
          {
            name  = "minecraft-bot"
            image = "${azurerm_container_registry.acr.login_server}/minecraft-bot:1.1"
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
                name  = "SEMANTIC_KERNEL_ENDPOINT"
                value = "https://${jsondecode(azapi_resource.sk_minimal_api.output).properties.configuration.ingress.fqdn}"
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
}
