#!/usr/bin/env zsh

if [ -f /var/run/docker.sock ]; then
  sudo chgrp docker /var/run/docker.sock
fi

exec $@
