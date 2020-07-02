# Ubuntu development environment with Visual Studio Code editor and IntelliJ

Based on the official Ubuntu 18.04, this image installs

- [Go](https://golang.org)
- [OpenJDK 11](https://openjdk.java.net/)
- [Rust](https://www.rust-lang.org/)
- [Node.js](https://nodejs.org/en/)
- [Typescript](https://www.typescriptlang.org/)
- [.Net Core](https://dotnet.microsoft.com/)
- [Docker](https://www.docker.com/)
- [Code Server](https://github.com/cdr/code-server)
- [Jetbrains IntelliJ](https://www.jetbrains.com/idea/)
- [Postman Rest Client](https://www.postman.com/)
- [AWS Command Line Interface](https://aws.amazon.com/cli/)
- [Terraform](https://www.terraform.io/)

along with a few other useful development tools

## Instructions

### Build

Use the sample.env to create a .env file with your environment variables.

By default the build script will use the current user name when creating a user for the container. The user is created and the sudoers file is updated to allow the user to run sudo without a password.

If you prefer to use a different user name in the container, you can specify it by setting the USER_NAME environment variable in the .env file.

#### Example

```bash
# .env
USER_NAME=my_user
```

### Install

Once you have set these run `make` to build the docker image.

### Visual Studio Code Server

Code server is a project that takes Visual Studio Code OSS version and makes it run as a web application so you can run Visual Studio Code in your browser. This docker image takes advantage of this Visual Studio Code server by launching it as default with a fully comprehenive stack of tools for doing a multitude of development tasks. The Dockerfile also serves as a starting point/example for creating and tweaking your own development environment to suit your needs.

The code server is installed to `/code-server` and permissions are changed to the specified user account. Extensions are installed to the `/code-server/extensions` folder, and if a container is created without passing any parameters, then the user data directory is set to `/code-server/user-data`.

This allows you to override the pre-installed extensions with your own choice of extensions by mapping your local extensions folder to `/code-server/extensions` and to persist your Visual Studio code personal settings, between containers, you can map `/code-server/user-data/User` to a location on your host machine or another docker volume.

#### Examples

I have my project libraries in a folder called at `$HOME/code` and I want to start a Visual Studio Code server to work on my project. My docker image was created with a user account called `user`

```bash
docker run -d -v $HOME/code:/home/user/code -p 8080:8080 birchwoodlangham/dockerised-development-environment:latest
```

This will create a container running the code server with my code folder mapped to the code folder under the `user` home directory. I have mapped port 8080 to my host port 8080 so I can access the code server. Using any web browser, I can now navigate to `http://localhost:8080` open up any of my projects and start working on them.

To use your own extensions and to save your settings between containers

```bash
docker run -v /path/to/my/extensions:/code-server/extensions -v /path/to/my/config:/code-server/user-data/User -p 8080:8080 birchwoodlangham/dockerised-development-environment:latest
```

### CLI

If you only want a shell environment, you can simply run the image and specify the shell you want, e.g. bash, sh, or zsh

```bash
docker run -it birchwoodlangham/dockerised-development-environment:latest zsh
```

### GUI Applications

To run GUI applications such as IntelliJ or Postman etc., you will need to disable local X access control and map a few other resources to your container:

```bash
xhost +local:$(whoami)

docker run -d --rm \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v /run/user/$(id -u):/run/user/$(id -u) \
  -e DISPLAY=$DISPLAY \
  -e DBUS_SESSION_BUS_ADDRESS="unix:path=/var/run/user/1000/bus" \
  --ipc=host \
  --security-opt=seccomp:unconfined \
  birchwoodlangham/dockerised-development-environment:latest idea.sh
```

> **WARNING** Disabling X access control is a security risk, you should only do so if you know what you are doing

### Docker

If you intend to access the host's Docker environment from inside your docker container, you will also need to add an extra mapping for the docker socket:

```bash
docker run -d --rm \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /run/user/$(id -u):/run/user/$(id -u) \
  -e DISPLAY=$DISPLAY \
  -e DBUS_SESSION_BUS_ADDRESS="unix:path=/var/run/user/1000/bus" \
  --ipc=host \
  --security-opt=seccomp:unconfined \
  birchwoodlangham/dockerised-development-environment:latest idea.sh
```

### IntelliJ settings

If you want your IntelliJ settings to persist even after the container has been destroyed, you can do so by mapping a volume from your host or a docker volume to the ~/IntelliJIdea2019.3 folder in the container, so for example if the user is called `user`:

```bash
docker run -d --rm \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /run/user/$(id -u):/run/user/$(id -u) \
  -v $HOME/.IntelliJIdea2019.3:/home/user/.IntelliJIdea2019.3 \
  -e DISPLAY=$DISPLAY \
  -e DBUS_SESSION_BUS_ADDRESS="unix:path=/var/run/user/1000/bus" \
  --ipc=host \
  --security-opt=seccomp:unconfined \
  birchwoodlangham/dockerised-development-environment:latest idea.sh
```

### Other settings

Additionally you may want to map other configurations for your git configuration, personal fonts, ssh keys and project files when starting a container, regardless if you prefer to use Visual Studio Code or IntelliJ:

```bash
docker run -d --rm \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /run/user/$(id -u):/run/user/$(id -u) \
  -v $HOME/code:/home/user/code \
  -v $HOME/.ssh:/home/user/.ssh \
  -v $HOME/.netrc:/home/user/.netrc \
  -v $HOME/.gitconfig:/home/user/.gitconfig \
  -v $HOME/.IntelliJIdea2019.3:/home/user/.IntelliJIdea2019.3 \
  -v $HOME/.java:/home/user/.java \
  -v $HOME/.fonts:/home/user/.fonts \
  -v $HOME/code-server/extensions:/code-server/extensions \
  -v $HOME/code-server/user-data/User:/code-server/user-data/User \
  -e DISPLAY=$DISPLAY \
  -e DBUS_SESSION_BUS_ADDRESS="unix:path=/var/run/user/1000/bus" \
  --ipc=host \
  --security-opt=seccomp:unconfined \
  birchwoodlangham/dockerised-development-environment:latest
```

### MacOS

For MacOS the procedure is slightly different if you want to run GUI applications.

Unfortunately, there are a number of pre-requisite steps you will need to undertake before you can launch any X applications on MacOS.

1. As this Docker container is Linux based, in order to display the application, you will need to have a X11 service installed in order to launch a GUI application
2. XQuartz can provide an X11 service and you can install it using homebrew with ```brew cask install xquartz```
3. After you install, launch XQuartz using ```open -a XQuartz``` and then check the Security tab and make sure the **Allow connections from network clients** option is checked

Once you have done that, then to run an GUI application from the container, you need to make sure XQuartz has been started before you launch the containerised GUI application.

```bash
open -a XQuartz

docker run -d --rm \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /run/user/$(id -u):/run/user/$(id -u) \
  -e DISPLAY=$DISPLAY \
  -e DBUS_SESSION_BUS_ADDRESS="unix:path=/var/run/user/1000/bus" \
  --ipc=host \
  --security-opt=seccomp:unconfined \
  birchwoodlangham/dockerised-development-environment:latest idea.sh
```

### AWS Command Line Interface

To pass your AWS credentials, you can edit pass them in as environment variables that are recognised by the AWS CLI. These are:

- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY

Alternatively, if you can mount the .aws folder from your host machine to the docker container.

## Change Log

============

2020-07-02: Version bump and re-instate dotnet core now that the repos are working properly
2020-04-30: Version bump for Go, IntelliJ etc.
2020-04-06: Added vimrc configurations, updated Nodejs to current version, installed Typescript and .Net Core, replaced IntelliJ with the version including the JBR
2020-04-05: Hotfix: could not use docker without using sudo. Additionally installed aws cli and terraform
2020-04-05: Updated the image to use Visual Studio Code server and added make file, launcher scripts etc.
2019-09-19: Version bump on Go, Scala, SBT, IntelliJ, Protocol buffers etc.
2019-09-20: Added Microsoft Cascadia Font to font collection
2019-11-27: Version bump
