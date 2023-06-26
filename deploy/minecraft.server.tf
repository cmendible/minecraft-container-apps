resource "azapi_resource" "minecraft_server" {
  name      = "mc-server"
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
          targetPort = 25565
          transport  = "Tcp"

          traffic = [
            {
              latestRevision = true
              weight         = 100
            }
          ]
        }
        dapr = {
          enabled = true
          appId   = "mc"
        }
      }
      template = {
        containers = [
          {
            name  = "mc"
            image = "itzg/minecraft-server"
            resources = {
              cpu    = 1.5
              memory = "3Gi"
            }
            env = [
              {
                name  = "EULA"
                value = "TRUE"
              },
              {
                name  = "ONLINE_MODE"
                value = "FALSE"
              },
              {
                name  = "OVERRIDE_OPS"
                value = "FALSE"
              },
              {
                name  = "OPS_FILE"
                value = "ops.json"
              },
              {
                name  = "ENABLE_RCON"
                value = "TRUE"
              },
              {
                name  = "SPAWN_MONSTERS"
                value = "FALSE"
              },
              {
                name  = "TYPE"
                value = "SPIGOT"
              },
              {
                name  = "VERSION"
                value = "1.17.1"
              },
              {
                name  = "MODE"
                value = "creative"
              }
            ],
            volumeMounts = [
              {
                volumeName = "data-volume"
                mountPath  = "/data"
              }
            ]
          }
        ]
        scale = {
          minReplicas = 1
          maxReplicas = 1
        }
        volumes = [
          {
            name        = "data-volume"
            storageName = "${azurerm_container_app_environment_storage.data.name}"
            storageType = "AzureFile"
          }
        ]
      }
    }
  })
  response_export_values = ["properties.configuration.ingress.fqdn"]
}