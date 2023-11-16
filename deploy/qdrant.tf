resource "azapi_resource" "qdrant" {
  depends_on = [azurerm_container_registry_task.sk_api_acr_task]
  name       = "qdrant"
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
        secrets = [
          
        ]
        ingress = {
          external   = true
          targetPort = 6333
          transport  = "Http"
        }
      }
      template = {
        containers = [
          {
            name  = "qdrant"
            image = "qdrant/qdrant"
            resources = {
              cpu    = 0.75
              memory = "1.5Gi"
            }
            env = [             
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
