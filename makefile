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
DOCKER_GROUP_ID ?= $(shell getent group docker | awk -F: '{print $$3}')

build:
	docker build \
	--build-arg user=${USER_NAME} \
	--build-arg docker_group_id=${DOCKER_GROUP_ID} \
	-t birchwoodlangham/dockerised-development-environment:${TAG} \
	-t birchwoodlangham/dockerised-development-environment:latest .

install:
	mkdir -p ~/.config/dev-env/envfiles
	mkdir -p ~/.local/bin
	mkdir -p ~/.config/code-server/default/extensions
	mkdir -p ~/.config/code-server/default/user-data/User
	mkdir -p ~/.config/systemd/user
	cp dev-env/* ~/.config/dev-env
	cp -R envfiles/* ~/.config/dev-env/envfiles
	cp denv ~/.local/bin

ifneq (,$(wildcard .env))		# Only copy the .env file if it exists
	cp .env ~/.config/dev-env
endif

ifeq (,$(wildcard ~/.config/systemd/user/code-server.service)) # Only copy the code-server.service file if it doesn't exist
	cp code-server.service ~/.config/systemd/user
endif

uninstall:
	rm -rf ~/.config/dev-env/docker-compose*.yaml
	rm -rf ~/.config/dev-env/envfiles
	rm -f ~/.local/bin/denv
	rm -f ~/.config/dev-env/.env
	rm -f ~/.config/systemd/user/code-server.service

