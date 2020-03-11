#!/bin/bash

cd /app/mapping-r-server/target/bin
until ./r_server; do
    echo "R Server crashed with exit code $?.  Respawning.." >&2
    sleep 1
done
