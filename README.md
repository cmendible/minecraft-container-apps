docker build -t cmendibl3/dapr.sensors.actors:0.1.0 -f .\dapr.actors.Dockerfile .
docker build -t cmendibl3/dapr.sensors.client:0.1.0 -f .\dapr.client.Dockerfile .
docker build -t cmendibl3/dapr.sensors.average:0.1.0 -f .\dapr.sensors.average.Dockerfile .
docker build -t cmendibl3/dapr.minecraft.poll:0.1.0 -f .\dapr.minecraft.poll.Dockerfile .


docker push cmendibl3/dapr.sensors.actors:0.1.0
docker push cmendibl3/dapr.sensors.client:0.1.0
docker push cmendibl3/dapr.sensors.average:0.1.0
docker push cmendibl3/dapr.minecraft.poll:0.1.0

terraform apply

---

env:DEBUG="minecraft-protocol"  