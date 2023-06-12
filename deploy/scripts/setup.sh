#!/bin/sh

mkdir -p /data/plugins/

# https://github.com/ediloren/ScriptCraft
wget -O- https://github.com/ediloren/ScriptCraft/raw/development/target/scriptcraft.jar > /data/plugins/scriptcraft.jar

wget -O- https://github.com/graalvm/graalvm-ce-builds/releases/download/vm-21.2.0/graalvm-ce-java16-linux-amd64-21.2.0.tar.gz > /graalvm/graalvm.tar.gz

tar -xzf /graalvm/graalvm.tar.gz -C /graalvm

rm /graalvm/graalvm.tar.gz

wget -O- https://github.com/Tiiffi/mcrcon/releases/download/v0.7.1/mcrcon-0.7.1-linux-x86-64.tar.gz > /mcrcon/mcrcon.tar.gz

tar -xzf /mcrcon/mcrcon.tar.gz -C /mcrcon

rm /mcrcon/mcrcon.tar.gz