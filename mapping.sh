#!/bin/bash

PORT=10000
export FCGI_WEB_SERVER_ADDRS=127.0.0.1

cd /app/mapping-core/target/bin
until spawn-fcgi -n -p $PORT mapping_cgi; do
    echo "Mapping crashed with exit code $?.  Respawning.." >&2
    sleep 1
done
