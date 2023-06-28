# Variables
RESOURCE_GROUP="minecraft-stuff"
LOCATION="westeurope"
AZ_OPENAI_NAME="minecraftopenai"

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create Azure Open AI resource
az cognitiveservices account create \
-n $AZ_OPENAI_NAME \
-g $RESOURCE_GROUP \
-l $LOCATION \
--kind OpenAI \
--sku s0

# Deploy GTP35
az cognitiveservices account deployment create \
-g $RESOURCE_GROUP \
-n $AZ_OPENAI_NAME \
--deployment-name gpt-35-turbo \
--model-name gpt-35-turbo \
--model-version "0301"  \
--model-format OpenAI \
--scale-settings-scale-type "Standard"

export AZURE_OPENAI_ENDPOINT=$(az cognitiveservices account show -n $AZ_OPENAI_NAME -g $RESOURCE_GROUP --query "properties.endpoint" -o tsv)
export AZURE_OPENAI_API_KEY=$(az cognitiveservices account keys list -n $AZ_OPENAI_NAME -g $RESOURCE_GROUP --query "key1" -o tsv)
export AZURE_OPENAI_DEPLOYMENT="gpt-35-turbo"
export MINECRAFT_HOST="localhost"
export MINECRAFT_BOT_NAME="0GiS0"
export MINECRAFT_PORT=25565

node main.ts

# Run minecraft server on docker
docker run -p 25565:25565 --name minecraft-server -e EULA=TRUE -e VERSION=1.17.1 -e OPS=cmendibl3,lordvanmanu,vicky,0Gis0 -e ONLINE_MODE=FALSE itzg/minecraft-server:latest