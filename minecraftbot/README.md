https://github.com/PrismarineJS/mineflayer/blob/master/docs/api.md

node main.ts

docker build -t cmendibl3/minecraft-bot:0.1.0 .
docker push cmendibl3/minecraft-bot:0.1.0 

dapr run -a bot -p 8080 --components-path ..\components\ -- node main.ts