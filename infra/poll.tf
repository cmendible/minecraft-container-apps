resource "azapi_resource" "poll" {
  name      = "public-poll"
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
        secrets = []
        ingress = {
          external      = true
          targetPort    = 8080
          transport     = "http"
          allowInsecure = true

          traffic = [
            {
              latestRevision = true
              weight         = 100
            }
          ]
        }
        dapr = {
          enabled     = true
          appId       = "public-poll"
          appProtocol = "http"
          appPort     = 8080
        }
      }
      template = {
        containers = [
          {
            name  = "public-poll"
            image = var.poll_image
            resources = {
              cpu    = 0.5
              memory = "1Gi"
            }
            env = []
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
