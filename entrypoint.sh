#!/usr/bin/env zsh

if [ -f /var/run/docker.sock ]; then
  sudo setfacl -m user:$(whoami):rw /var/run/docker.sock
fi

exec $@
