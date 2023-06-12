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

  body = jsonencode({
    properties : {
      managedEnvironmentId = "${azurerm_container_app_environment.cae.id}"
      configuration = {
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
            image = "cmendibl3/minecraft-bot"
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
                value = "vicky"
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