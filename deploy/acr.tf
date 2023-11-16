resource "azurerm_container_registry" "acr" {  
  name                = "arc${local.name_sufix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

# Create ACR task for Minimal Semantic Kernel API
resource "azurerm_container_registry_task" "sk_api_acr_task" {
  name                  = "generate-sk-minimal-api"
  container_registry_id = azurerm_container_registry.acr.id

  platform {
    os = "Linux"
  }

  docker_step {
    dockerfile_path      = "Dockerfile"
    context_path         = "https://github.com/0gis0/minecraft-container-apps#main:sk-minimal-api"
    context_access_token = var.gh_token
    image_names          = ["sk-minimal-api:1.2"]
  }

  provisioner "local-exec" {
    # Execute ACR task
    command = "az acr task run --registry ${azurerm_container_registry.acr.name} --name ${azurerm_container_registry_task.sk_api_acr_task.name}"
  }    

}


# Create ACR task for Minecraft bot
resource "azurerm_container_registry_task" "minecraft_bot_task" {
  name                  = "generate-minecraft-bot"
  container_registry_id = azurerm_container_registry.acr.id

  platform {
    os = "Linux"
  }

  docker_step {
    dockerfile_path      = "Dockerfile"
    context_path         = "https://github.com/0gis0/minecraft-container-apps#main:minecraftbot"
    context_access_token = var.gh_token
    image_names          = ["minecraft-bot:1.1"]
  }

  provisioner "local-exec" {
    # Execute ACR task
    command = "az acr task run --registry ${azurerm_container_registry.acr.name} --name ${azurerm_container_registry_task.minecraft_bot_task.name}"
  }    

}
