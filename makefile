.DEFAULT_GOAL := build
.SILENT: build install uninstall

build:
	./build.sh

install:
	mkdir -p ~/.config/dev-env/envfiles
	cp dev-env/* ~/.config/dev-env
	cp -R envfiles/* ~/.config/dev-env/envfiles
	cp denv ~/.local/bin

uninstall:
	rm -rf ~/.config/dev-env/docker-compose*.yaml
	rm -rf ~/.config/dev-env/envfiles
	rm -f ~/.local/bin/denv
