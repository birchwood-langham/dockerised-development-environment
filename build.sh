#!/usr/bin/env bash

if [[ -z $VERSION ]]; then
  echo 'VERSION has not been set, cannot continue'
  exit 1
fi

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

docker build --build-arg password="${USER_NAME}:${USER_PASSWORD}" --build-arg user=${USER_NAME} -t birchwoodlangham/dockerised-development-environment:${VERSION} .
docker tag birchwoodlangham/dockerised-development-environment:${VERSION} birchwoodlangham/dockerised-development-environment:latest
