resource "azurerm_container_registry" "acr" {
  #   name                = "${replace(random_pet.prefix.id, "-", "")}acr"
  name                = "arc${local.name_sufix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

# Create ACR task - for GH Runner Linux
resource "azurerm_container_registry_task" "linux_acr_task" {
  name                  = "generate-sk-minimal-api"
  container_registry_id = azurerm_container_registry.acr.id

  platform {
    os = "Linux"
  }

  docker_step {
    dockerfile_path      = "sk-minimal-api/Dockerfile"
    context_path         = "https://github.com/0gis0/minecraft-container-apps"
    context_access_token = var.gh_token
    image_names          = ["sk-minimal-api:1.0"]
  }

  provisioner "local-exec" {
    # Execute ACR task
    command = "az acr task run --registry ${azurerm_container_registry.acr.name} --name ${azurerm_container_registry_task.linux_acr_task.name}"
  }
}
