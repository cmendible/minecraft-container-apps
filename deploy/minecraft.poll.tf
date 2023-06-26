resource "azapi_resource" "dapr_minecraft_poll" {
  name      = "dapr-minecraft-poll"
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
        ingress = {
          external   = true
          targetPort = 80
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
          appId   = "dapr-minecraft-poll"
        }
      }
      template = {
        containers = [
          {
            name  = "dapr-minecraft-poll"
            image = "cmendibl3/dapr.minecraft.poll:0.1.0"
            resources = {
              cpu    = 0.5
              memory = "1Gi"
            }
            env = [],
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
