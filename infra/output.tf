output "mi_id" {
  value     = azurerm_user_assigned_identity.mi.id
  sensitive = true
}

output "mi_client_id" {
  value     = azurerm_user_assigned_identity.mi.client_id
  sensitive = true
}

output "minecraft_server_fqdn" {
  value = azapi_resource.minecraft_server.output.properties.configuration.ingress.fqdn
}

output "openai_endpoint" {
  value = azurerm_cognitive_account.openai.endpoint
}

output "openai_key" {
  sensitive = true
  value     = azurerm_cognitive_account.openai.primary_access_key
}
