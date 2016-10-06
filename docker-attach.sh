#!/bin/sh -eu

DID="$(docker ps | grep 'cytopia/apache-2.4' | awk '{print $1}')"
docker exec -i -t "${DID}" env TERM=xterm /bin/bash -l

