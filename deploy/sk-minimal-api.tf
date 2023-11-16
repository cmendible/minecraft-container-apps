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
            value = "${azurerm_cognitive_account.openai.primary_access_key}"
          },
          {
            name  = "openaikey"
            value = "${var.openai_key}}"
          },
          {
            name  = "acrpassword"
            value = azurerm_container_registry.acr.admin_password
          }
        ]
        ingress = {
          external   = true
          targetPort = 8080
          transport  = "Http"
        }
      }
      template = {
        containers = [
          {
            name  = "api"
            image = "${azurerm_container_registry.acr.login_server}/sk-minimal-api:4.0"
            resources = {
              cpu    = 0.75
              memory = "1.5Gi"
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
                value = "${azurerm_cognitive_account.openai.endpoint}"
              },
              {
                name      = "openaiKey"
                secretRef = "openaikey"
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
