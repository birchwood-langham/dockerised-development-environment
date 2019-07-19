#!/usr/bin/env bash

if [[ -f .env ]]; then 
  echo Sourcing environment variables from .env
  source .env
fi

if [[ -z $USER_PASSWORD ]]; then
  echo Password for the container user has not been set, terminating
  exit 1
fi

if [[ -z $USER_NAME ]]; then
  USER_NAME=$(id -u)
fi

if [[ -z $CODE_VERSION ]]; then
  CODE_VERSION=1.36.1
fi

docker build --build-arg password="${USER_NAME}:${USER_PASSWORD}" --build-arg user=${USER_NAME} -t birchwoodlangham/code-dev-environment:${CODE_VERSION} .
docker tag birchwoodlangham/code-dev-environment:${CODE_VERSION} birchwoodlangham/code-dev-environment:latest
