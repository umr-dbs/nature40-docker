#!/bin/bash

if ! test -f "/app/userdb/userdb.sqlite"; then
  ./init_userdb.sh
fi

./mapping.sh &

./r_server.sh &

apachectl -D FOREGROUND
