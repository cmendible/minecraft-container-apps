#!/bin/sh

while  [ ! -f  "/data/scriptcraft/plugins/spawn.js" ]; do 
    sleep 1 # wait 2 for scriptcraft to be unzipped
done

cp /setup/netcoreconf.js /data/scriptcraft/plugins/netcoreconf.js

while  [ ! -f  "/data/scriptcraft/modules/http/request.js" ]; do 
    sleep 1 # wait 2 for scriptcraft to be unzipped
done

cp /setup/request.js /data/scriptcraft/modules/http/request.js

while  [ ! -f  "/data/scriptcraft/plugins/spawn.js" ]; do 
    sleep 1 # wait 2 for scriptcraft to be unzipped
done

cp /setup/setsigntext.js /data/scriptcraft/plugins/setsigntext.js

apt-get update
apt-get install netcat -y

while ! nc -z localhost 25575; do   
    sleep 5 # wait 5 seconds for rcon
done

/mcrcon/mcrcon-0.7.1-linux-x86-64/mcrcon -p rcon231418. "op cmendibl3" "op lordvanmanu"

while true; do sleep 3600; done
