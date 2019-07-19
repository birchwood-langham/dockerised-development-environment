#!/usr/bin/env zsh

groupmod -g $(stat -c %g /var/run/docker.sock) docker
chown -R USER_NAME:USER_NAME /home/USER_NAME

exec gosu USER_NAME $@
