#!/usr/bin/env bash

TAG=$(git describe --tags --always --dirty | sed 's/-g[a-z0-9]\{7\}//')
USER_NAME=$(id -un)

docker build --build-arg user=${USER_NAME} -t birchwoodlangham/dockerised-development-environment:${TAG} .
docker tag birchwoodlangham/dockerised-development-environment:${TAG} birchwoodlangham/dockerised-development-environment:latest
