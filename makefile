ifneq (,$(wildcard ./.env))
	include .env
	export
endif

.DEFAULT_GOAL := build
.SILENT: build install uninstall

USER_ID ?= $(shell id -u)
USER_NAME ?= $(shell id -un)
MAINTAINER ?= "$(shell git config user.name) <$(shell git config user.email)>"

REPO ?= birchwoodlangham
PROJECT ?= dockerised-development-environment
TAG ?= $(shell git describe --tags --always --dirty | sed 's/-g[a-z0-9]\{7\}//')
CONTAINER_NAME ?= ${DOCKER_REGISTRY}/${REPO}/${PROJECT}

build:
	docker build --build-arg user=${USER_NAME} -t birchwoodlangham/dockerised-development-environment:${TAG} .
	docker tag birchwoodlangham/dockerised-development-environment:${TAG} birchwoodlangham/dockerised-development-environment:latest

install:
	mkdir -p ~/.config/dev-env/envfiles
	mkdir -p ~/.local/bin
	mkdir -p ~/.config/code-server/default/extensions
	mkdir -p ~/.config/code-server/default/user-data/User
	cp dev-env/* ~/.config/dev-env
	cp -R envfiles/* ~/.config/dev-env/envfiles
	cp denv ~/.local/bin
ifneq (,$(wildcard .env))		# Only copy the .env file if it exists
	cp .env ~/.config/dev-env
endif

uninstall:
	rm -rf ~/.config/dev-env/docker-compose*.yaml
	rm -rf ~/.config/dev-env/envfiles
	rm -f ~/.local/bin/denv
	rm -f ~/.config/dev-env/.env
