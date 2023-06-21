resource "azapi_resource" "dapr_sensors_actors" {
  name      = "dapr-sensors-actors"
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
          external   = false
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
          appId   = "dapr-sensors-actors"
        }
      }
      template = {
        containers = [
          {
            name  = "dapr-sensors-actors"
            image = "cmendibl3/dapr.sensors.actors:0.1.0"
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

resource "azapi_resource" "dapr_sensors_client" {
  name      = "dapr-sensors-client"
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
        dapr = {
          enabled = true
          appId   = "dapr-sensors-client"
        }
      }
      template = {
        containers = [
          {
            name  = "dapr-sensors-actors"
            image = "cmendibl3/dapr.sensors.client:0.1.0"
            resources = {
              cpu    = 0.5
              memory = "1Gi"
            }
             command = [
              "sh",
              "-c",
              "sleep 10 && dotnet dapr.sensors.client.dll"
            ]
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

resource "azapi_resource" "dapr_sensors_average" {
  name      = "dapr-sensors-average"
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
          external   = false
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
          appId   = "dapr-sensors-average"
        }
      }
      template = {
        containers = [
          {
            name  = "dapr-sensors-average"
            image = "cmendibl3/dapr.sensors.average:0.1.0"
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
      managedEnvironmentId = "${azurerm_container_app_environment.cae.id}"
      configuration = {
        ingress = {
          external   = false
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
            image = "manuss20/dapr.minecraft.poll:0.1.0"
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