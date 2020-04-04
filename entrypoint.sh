#!/usr/bin/env zsh

if [ -f /var/run/docker.sock ]; then
  sudo groupmod -g $(stat -c %g /var/run/docker.sock) docker
fi

exec $@
