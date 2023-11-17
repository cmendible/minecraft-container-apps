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

variable "gh_token" {
  default = "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"
}

variable "openai_key" {
  sensitive = true
}

variable "azure_openai_api_key" {
  
}

variable "azure_oai_endpoint"{
  default = "https://semantic-kernel-models.openai.azure.com/"
}