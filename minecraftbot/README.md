https://github.com/PrismarineJS/mineflayer/blob/master/docs/api.md

export MINECRAFT_HOST=20.82.84.49 
export MINECRAFT_PORT=25565
export MINECRAFT_BOT_NAME="vicky"
export AZURE_OPENAI_ENDPOINT="<endpoint>"
export AZURE_OPENAI_API_KEY="<key>"
export AZURE_OPENAI_DEPLOYMENT="gpt-35-turbo"
node main.ts

docker build -t cmendibl3/minecraft-bot .
docker push cmendibl3/minecraft-bot 

dapr run -a bot -p 8080 --components-path ..\components\ -- node main.ts