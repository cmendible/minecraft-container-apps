resource "azapi_resource" "code" {
  name      = "code-interpreter"
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
          transport     = "Http"
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
          appId       = "code-interpreter"
          appProtocol = "http"
          appPort     = 8080
        }
      }
      template = {
        containers = [
          {
            name  = "code-interpreter"
            image = var.code_interpreter_image
            resources = {
              cpu    = 0.5
              memory = "1Gi"
            }
            env = [
              {
                name  = "MODEL_ID"
                value = "gpt-35-turbo"
              },
              {
                name  = "API_KEY"
                value = "${azurerm_cognitive_account.openai.primary_access_key}"
              },
              {
                name  = "ENDPOINT"
                value = "${azurerm_cognitive_account.openai.endpoint}"
              },
              {
                name = "INTERPRETER_ENDPOINT"
                value = "${azapi_resource.code_interpreter.output.properties.poolManagementEndpoint}"
              },
              {
                name  = "AZURE_TENANT_ID"
                value = "${data.azurerm_client_config.current.tenant_id}"
              },
              {
                name  = "AZURE_CLIENT_ID"
                value = "${azurerm_user_assigned_identity.mi.client_id}"
              },
            ]
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
