variable "resource_group_name" {
  default = "rg-cae"
}

variable "managed_identity_name" {
  default = "mi-cae"
}

variable "location" {
  default = "eastus2"
}

variable "keyvault_name" {
  default = "kv-cae"
}

variable "cosmos_name" {
  default = "cosmos-cae"
}

variable "storage_name" {
  default = "stcae"
}

variable "eventhub_name" {
  default = "evh-cae"
}

variable "cae_name" {
  default = "cae"
}

variable "logws_name" {
  default = "logws-cae"
}

variable "aoai_name" {
  default = "aoai-minecraft-bot"
}

variable "minecraft_bot_image" {
  default = "ghcr.io/cmendible/minecraft-container-apps/minecraft-bot:1.0.0-preview.51"
}

variable "weather_plugin_image" {
  default = "ghcr.io/cmendible/minecraft-container-apps/weather-plugin:1.0.0-preview.51"
}

variable "poll_image" {
  default = "ghcr.io/cmendible/minecraft-container-apps/public-poll:1.0.0-preview.51"
}
