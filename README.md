## Deploy the Azure infrastructure

```bash
cd infra
export ARM_SUBSCRIPTION_ID="<your-azure-subscription-id>"
terraform apply
```

## Prepare the environment

```bash
cd agent-demos
dapr init
pip install dapr-agents
pip install -r requirements.txt
```

## Create a .env file with the following content:

```bash
AZURE_OPENAI_API_KEY="<your-azure-openai-api-key>"
AZURE_OPENAI_ENDPOINT="<your-azure-openai-endpoint>"
AZURE_OPENAI_DEPLOYMENT="gpt-4.1"
AZURE_OPENAI_API_VERSION="2024-12-01-preview"
DAPR_LLM_COMPONENT_DEFAULT="openai"
MINECRAFT_SERVER="<your-minecraft-server>"
```

## Run the demos

```bash
dapr run -f dapr-01.yaml
dapr run -f dapr-02.yaml
dapr run -f dapr-03.yaml
```

## Prepare the minecraft mcp server

```bash
cd minecraft-mcp-server
npm install
npm run build
```

## Run the minecraft demo

```bash
dapr run -f dapr-04.yaml
```

## Enable Redis Insights

```bash
docker run --rm -d --name redisinsight -p 5540:5540 redis/redisinsight:latest
```

### Connection Configuration:

* Port: 6379
* Host (Linux): 172.17.0.1