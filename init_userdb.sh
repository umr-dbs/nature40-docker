#!/bin/bash

MYPWD=${PWD}  #or MYPWD=$(pwd)
cd /app/mapping-core/target/bin
./mapping_manager userdb adduser guest guest guest guest
cd $MYPWD