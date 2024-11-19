#!/bin/bash

# copies file into docker-entrypoint-initdb.d
cp /tmp/initdb.sql /docker-entrypoint-initdb.d/

/usr/local/bin/docker-entrypoint.sh postgres -c wal_level=logical &

