resource "azurerm_container_app_environment" "cae" {
  name                       = local.cae_name
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id
  infrastructure_subnet_id   = azurerm_subnet.apps.id
}

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
      managedEnvironmentId = "${azurerm_container_app_environment.cae.id}"
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
        initContainers = [
          {
            name  = "spigot-setup"
            image = "busybox"
            resources = {
              cpu    = 0.25
              memory = "0.5Gi"
            }
            command = [
              "sh",
              "-c",
              "/setup/setup.sh"
            ]
            volumeMounts = [
              {
                volumeName = "data-volume"
                mountPath  = "/data"
              },
              {
                volumeName = "java-volume"
                mountPath  = "/graalvm"
              },
              {
                volumeName = "rcon-volume"
                mountPath  = "/mcrcon"
              },
              {
                volumeName = "setup-volume"
                mountPath  = "/setup"
              }
            ]
          }
        ]
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
                name  = "AZURE_OPENAI_ENDPOINT"
                value = "${azurerm_cognitive_account.openai.endpoint}"
              },
              {
                name  = "AZURE_OPENAI_API_KEY"
                value = "${azurerm_cognitive_account.openai.primary_access_key}"
              },
              {
                name  = "EULA"
                value = "TRUE"
              },
              {
                name  = "JVM_DD_OPTS"
                value = "polyglot.js.nashorn-compat=true"
              },
              {
                name  = "ONLINE_MODE"
                value = "FALSE"
              },
              {
                name  = "OPS"
                value = "cmendibl3,lordvanmanu,vicky,0Gis0"
              },
              {
                name  = "OVERRIDE_OPS"
                value = "TRUE"
              },
              {
                name  = "ENABLE_RCON"
                value = "TRUE"
              },
              {
                name  = "RCON_PASSWORD"
                value = "rcon231418."
                }, {
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
              },
              {
                name  = "PATH"
                value = "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/graalvm/graalvm-ce-java16-21.2.0/bin"
              },
              {
                name  = "JAVA_HOME"
                value = "/graalvm/graalvm-ce-java16-21.2.0"
              }
            ],
            volumeMounts = [
              {
                volumeName = "java-volume"
                mountPath  = "/graalvm"
              },
              {
                volumeName = "rcon-volume"
                mountPath  = "/mcrcon"
              },
              {
                volumeName = "setup-volume"
                mountPath  = "/setup"
              },
              {
                volumeName = "data-volume"
                mountPath  = "/data"
              }
            ]
          },
          {
            name  = "spigot-ops-fix"
            image = "ubuntu"
            resources = {
              cpu    = 0.25
              memory = "0.5Gi"
            }
            command = [
              "sh",
              "-c",
              "/setup/ops-fix.sh"
            ]
            # args = [
            # ]
            volumeMounts = [
              {
                volumeName = "rcon-volume"
                mountPath  = "/mcrcon"
              },
              {
                volumeName = "setup-volume"
                mountPath  = "/setup"
              },
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
            name        = "java-volume"
            storageName = "${azurerm_container_app_environment_storage.java.name}"
            storageType = "AzureFile"
          },
          {
            name        = "rcon-volume"
            storageName = "${azurerm_container_app_environment_storage.rcon.name}"
            storageType = "AzureFile"
          },
          {
            name        = "setup-volume"
            storageName = "${azurerm_container_app_environment_storage.scripts.name}"
            storageType = "AzureFile"
          },
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

resource "azurerm_storage_account" "st" {
  name                     = local.storage_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_share" "share" {
  name                 = "minecraft"
  storage_account_name = azurerm_storage_account.st.name
  quota                = 5
}

resource "azurerm_storage_share" "scripts" {
  name                 = "scripts"
  storage_account_name = azurerm_storage_account.st.name
  quota                = 5
}

resource "azurerm_storage_share" "rcon" {
  name                 = "rcon"
  storage_account_name = azurerm_storage_account.st.name
  quota                = 5
}

resource "azurerm_storage_share" "java" {
  name                 = "java"
  storage_account_name = azurerm_storage_account.st.name
  quota                = 5
}

resource "azurerm_storage_share_file" "scripts" {
  for_each = fileset(path.module, "scripts/*")

  name             = replace(each.key, "scripts/", "")
  storage_share_id = azurerm_storage_share.scripts.id
  source           = each.key
}

resource "azurerm_storage_container" "container" {
  name                 = "subscribers"
  storage_account_name = azurerm_storage_account.st.name
}

resource "azurerm_container_app_environment_storage" "data" {
  name                         = "minecraftstorage"
  container_app_environment_id = azurerm_container_app_environment.cae.id
  account_name                 = azurerm_storage_account.st.name
  share_name                   = azurerm_storage_share.share.name
  access_key                   = azurerm_storage_account.st.primary_access_key
  access_mode                  = "ReadWrite"
}

resource "azurerm_container_app_environment_storage" "rcon" {
  name                         = "rcon"
  container_app_environment_id = azurerm_container_app_environment.cae.id
  account_name                 = azurerm_storage_account.st.name
  share_name                   = azurerm_storage_share.rcon.name
  access_key                   = azurerm_storage_account.st.primary_access_key
  access_mode                  = "ReadWrite"
}

resource "azurerm_container_app_environment_storage" "java" {
  name                         = "java"
  container_app_environment_id = azurerm_container_app_environment.cae.id
  account_name                 = azurerm_storage_account.st.name
  share_name                   = azurerm_storage_share.java.name
  access_key                   = azurerm_storage_account.st.primary_access_key
  access_mode                  = "ReadWrite"
}

resource "azurerm_container_app_environment_storage" "scripts" {
  name                         = "scripts"
  container_app_environment_id = azurerm_container_app_environment.cae.id
  account_name                 = azurerm_storage_account.st.name
  share_name                   = azurerm_storage_share.scripts.name
  access_key                   = azurerm_storage_account.st.primary_access_key
  access_mode                  = "ReadOnly"
}

resource "azurerm_container_app_environment_dapr_component" "secret" {
  name                         = "secretstore"
  container_app_environment_id = azurerm_container_app_environment.cae.id
  component_type               = "secretstores.azure.keyvault"
  version                      = "v1"

  metadata {
    name  = "vaultName"
    value = azurerm_key_vault.kv.name
  }

  metadata {
    name  = "azureEnvironment"
    value = "AZUREPUBLICCLOUD"
  }

  metadata {
    name  = "azureClientId"
    value = azurerm_user_assigned_identity.mi.client_id
  }
}

resource "azurerm_container_app_environment_dapr_component" "state" {
  name                         = "statedb"
  container_app_environment_id = azurerm_container_app_environment.cae.id
  component_type               = "state.azure.cosmosdb"
  version                      = "v1"

  secret {
    name  = "masterkey"
    value = azurerm_cosmosdb_account.db.primary_key
  }

  metadata {
    name  = "url"
    value = azurerm_cosmosdb_account.db.endpoint
  }

  metadata {
    name  = "database"
    value = azurerm_cosmosdb_sql_database.db.name
  }

  metadata {
    name  = "collection"
    value = "state"
  }

  metadata {
    name        = "masterKey"
    secret_name = "masterkey"
  }

  metadata {
    name  = "actorStateStore"
    value = "true"
  }
}

resource "azurerm_container_app_environment_dapr_component" "messagebus" {
  name                         = "messagebus"
  container_app_environment_id = azurerm_container_app_environment.cae.id
  component_type               = "pubsub.azure.eventhubs"
  version                      = "v1"

  secret {
    name  = "connectionstring"
    value = azurerm_eventhub_namespace.evh.default_primary_connection_string
  }

  secret {
    name  = "storageaccountkey"
    value = azurerm_storage_account.st.primary_access_key
  }

  metadata {
    name  = "enableEntityManagement"
    value = "false"
  }

  metadata {
    name  = "storageAccountName"
    value = azurerm_storage_account.st.name
  }

  metadata {
    name  = "storageContainerName"
    value = "subscribers"
  }

  metadata {
    name        = "connectionString"
    secret_name = "connectionstring"
  }

  metadata {
    name        = "storageAccountKey"
    secret_name = "storageaccountkey"
  }
}
