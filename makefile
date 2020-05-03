.DEFAULT_GOAL := build
.SILENT: build install uninstall

build:
	./build.sh

install:
	mkdir -p ~/.config/dev-env/envfiles
	mkdir -p ~/.local/bin
	mkdir -p ~/.config/code-server/extensions
	mkdir -p ~/.config/code-server/user-data/User
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
