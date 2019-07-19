# Ubuntu Gdevelopment environment with Visual Studio Code editor

Based on the official Ubuntu 18.04, this image installs Go, OpenJDK 11, Rust, Docker and Visual Studio Code

## Instructions

### Build

Create a .env file with the environment variable USER_PASSWORD to set the sudo password for the user.

By default the build script will use the current user name when creating a user for the container and set the password to whatever you specified in the USER_PASSWORD environment variable.

If you prefer to use a different user name in the container, you can specify it by setting the USER_NAME environment variable in the .env file.

#### Example

```bash
# .env
USER_NAME=my_user
USER_PASSWORD=my_password
```

Once you have set these use the provided `build.sh` build script to build the Docker image.

### Linux

#### Code

To launch this container, use the code-docker script provided to launch the Code editor. This will launch the a container and start Visual Studio Code. The code properties and configuration files will
be saved to `$HOME/.code-docker` in your host, and the GOPATH from the container will be mapped to `$HOME/go` on your host.

Additionally `$HOME/code` on your host will also be mapped to the same folder in the container allowing you to save your code on the host even after the container has been destroyed.

When you exit Visual Studio Code, the container will be destroyed.

#### CLI

To launch this container into a CLI environment, use the `start-dev-env` script. This will launch the container into a zsh shell and allow you to launch Code as you see fit.

### MacOS

For MacOS the procedure is slightly different, the code-docker-mac script will launch the application for you once you're ready.

Unfortunately, there are a number of pre-requisite steps you will need to undertake before the scipt will work correctly.

1. As this Docker container is Linux based, in order to display the application, you will need to have a X11 service installed in order to launch a GUI application
2. XQuartz can provide an X11 service and you can install it using homebrew with ```brew cask install xquartz```
3. After you install, launch Quartz using ```open -a XQuartz``` and then check the Security tab and make sure the **Allow connections from network clients** option is checked

Once you have done that, then running the script code-docker-mac should launch an XQuartz session along with the Atom editor from the container

## Exposed volumes

The script will map the folder $HOME/code/go and $HOME/.code-docker folder from your host machine to the relevant folders in the container.

With regards to the $HOME/develop/go path, this will become your $GOPATH location on the container. The $HOME/.code-docker will map to the $HOME/.config/Code folder so that you can change your atom preferences and have them persist, as well as installing plugins and making sure that they work properly.

## Change Log

=======
