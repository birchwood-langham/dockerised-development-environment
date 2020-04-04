.DEFAULT_GOAL := build
.SILENT: build, install, uninstall

build:
	./build.sh

install:
	mkdir -p ~/.local/bin/dev-env
	cp dev-env/* ~/.local/bin/dev-env
	cp -R envfiles ~/.local/bin/dev-env
	cp denv ~/.local/bin

uninstall:
	rm -rf ~/.local/bin/dev-env
	rm -f ~/.local/bin/denv
