FROM ubuntu:20.04

LABEL maintainer="tan.quach@birchwoodlangham.com"

ARG password
ARG user=user

ENV CT_VERSION=2.4.1 \
  GO_VERSION=1.14.4 \
  SBT_VERSION=1.3.13 \
  PROTOC_VERSION=3.12.3 \
  HELM_VERSION=3.2.4 \
  IDEA_VERSION=2020.1.2 \
  TERM=xterm-256color \
  CODE_SERVER_VERSION=3.4.1 \
  GOLANGCI_LINT_VERSION=1.27.0 \
  TERRAFORM_VERSION=0.12.28 \
  DOTNET_CLI_TELEMETRY_OPTOUT=1

RUN apt-get update && \
  apt-get -y upgrade && \
  apt-get -y install apt-utils && \
  TZ=UTC DEBIAN_FRONTEND=noninteractive apt-get -y install dialog git vim software-properties-common debconf-utils wget curl apt-transport-https \
  bzip2 iputils-ping telnet net-tools iproute2 acl

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --fix-missing libxext-dev libxrender-dev libxslt1.1 \
  libxtst-dev libgtk2.0-0 libcanberra-gtk-module libxss1 libxkbfile1 \
  gconf2 gconf-service libnotify4 libnss3 gvfs-bin xdg-utils 

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --fix-missing sudo zsh fonts-powerline \
  openjdk-11-jdk go-dep build-essential locales ca-certificates gnupg-agent \
  software-properties-common httpie unzip gosu git-flow awscli

RUN locale-gen en_US.UTF-8 && \
  fc-cache -f

# Setup user
RUN  useradd -d /home/${user} -m -U ${user} -G sudo -s /usr/bin/zsh 

# Allow the user to run sudo commands without requiring a password
RUN echo ${user}' ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

# Install Go globally and link to /usr/lib/go for compatibility with Arch host
RUN wget https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz && \
  tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz && \
  rm go${GO_VERSION}.linux-amd64.tar.gz && \
  ln -s /usr/local/go /usr/lib/go

# Install SBT and Scala
RUN  echo "deb https://dl.bintray.com/sbt/debian /" | sudo tee -a /etc/apt/sources.list.d/sbt.list && \
  curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823" | apt-key add && \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install sbt

# Install Docker 
# RUN curl https://get.docker.com | bash && \ 
RUN apt-get -y install docker-compose && \
  usermod -aG docker ${user} 

# Install protoc
RUN PROTOC_ZIP=protoc-${PROTOC_VERSION}-linux-x86_64.zip &&\
  curl -OL https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_VERSION}/$PROTOC_ZIP  &&\
  unzip -o $PROTOC_ZIP -d /usr/local bin/protoc  &&\
  rm -f $PROTOC_ZIP

# Install Kubernetes
RUN curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
  echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" >/etc/apt/sources.list.d/kubernetes.list && \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y kubectl

# Install Helm
RUN wget https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz && \
  tar xzf helm-v${HELM_VERSION}-linux-amd64.tar.gz && \
  mv linux-amd64/helm /usr/local/bin/ && \
  rm -f helm-v${HELM_VERSION}-linux-amd64.tar.gz &&\
  rm -fr linux-amd64

# Install Nodejs, Typescript and Yarn
RUN curl -sL https://deb.nodesource.com/setup_13.x | bash - && \
  curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
  echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs yarn && \
  npm install -g typescript

# Install Helm chart testing
RUN mkdir /ct && cd /ct && \ 
  curl -Lo chart-testing_${CT_VERSION}_linux_amd64.tar.gz https://github.com/helm/chart-testing/releases/download/v${CT_VERSION}/chart-testing_${CT_VERSION}_linux_amd64.tar.gz  && \
  tar xzf chart-testing_${CT_VERSION}_linux_amd64.tar.gz  && \
  chmod +x ct && sudo mv ct /usr/local/bin/  && \
  mv etc /etc/ct && \
  cd / && rm -fr /ct

# Install IntelliJ idea
RUN mkdir -p /opt/idea && \
  wget https://download.jetbrains.com/idea/ideaIU-${IDEA_VERSION}.tar.gz && \
  tar -C /opt/idea -zxf ideaIU-${IDEA_VERSION}.tar.gz --strip-components=1 && \
  rm ideaIU-${IDEA_VERSION}.tar.gz && \
  ln -s /opt/idea/bin/idea.sh /usr/local/bin/idea

# Install Postman
RUN wget https://dl.pstmn.io/download/latest/linux64 -O Postman-linux.tar.gz && \
  tar -C /opt -xf Postman-linux.tar.gz && \
  ln -s /opt/Postman/Postman /usr/local/bin/Postman && \
  rm Postman-linux.tar.gz

# Install Terraform
RUN wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
  unzip -d /usr/local/bin terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
  rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# Install .Net Core
# Temporarily disable for now because Microsoft dropped the ball on this one, how unusual?
RUN wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb && \
  dpkg -i packages-microsoft-prod.deb && \
  rm -f packages-microsoft-prod.deb && \
  add-apt-repository universe && \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get -y install dotnet-sdk-3.1

# Clean up apt
RUN apt-get autoremove -y -qq && \
  apt-get clean && rm -rf /var/lib/apt/lists/*

# Install visual studio code server
RUN wget https://github.com/cdr/code-server/releases/download/v${CODE_SERVER_VERSION}/code-server-${CODE_SERVER_VERSION}-linux-amd64.tar.gz && \
  tar -zxf code-server-${CODE_SERVER_VERSION}-linux-amd64.tar.gz --transform 's/code-server-.*-linux-amd64/code-server/' && \
  rm -f code-server-${CODE_SERVER_VERSION}-linux-amd64.tar.gz

# change ownership of the code-server to the container's user
RUN chown -R ${user}:${user} /code-server

# Now that we have done all the installations at a root leve we need, we will switch to the user
# context and continue installing user level applications and configuraions
USER ${user}
WORKDIR /home/${user}

# Install Oh My Zsh
RUN curl -Lo install.sh https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh && \
  sh install.sh --unattended && \
  rm install.sh

RUN git clone https://github.com/zplug/zplug .zplug

ENV GOPATH=/home/${user}/go
ENV GOROOT=/usr/lib/go
ENV CARGO_PATH=/home/${user}/.cargo
ENV PATH=$PATH:$GOROOT/bin:$GOPATH/bin:$CARGO_PATH/bin

# Set up Rust in the user environment    
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
  /home/${user}/.cargo/bin/rustup component add clippy llvm-tools-preview rls rust-analysis rustfmt rust-src

# Install Miniconda for Python environments
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
  sh Miniconda3-latest-Linux-x86_64.sh -b && \
  rm Miniconda3-latest-Linux-x86_64.sh

# Add the go tools required by the vscode.go plugin
RUN go get -u -v github.com/ramya-rao-a/go-outline  && \
  go get -u -v github.com/acroca/go-symbols  && \
  go get -u -v github.com/mdempsky/gocode  && \
  go get -u -v github.com/rogpeppe/godef  && \
  go get -u -v golang.org/x/tools/cmd/godoc  && \
  go get -u -v github.com/zmb3/gogetdoc  && \
  go get -u -v golang.org/x/lint/golint  && \
  go get -u -v github.com/fatih/gomodifytags  && \
  go get -u -v golang.org/x/tools/cmd/gorename  && \
  go get -u -v sourcegraph.com/sqs/goreturns  && \
  go get -u -v golang.org/x/tools/cmd/goimports  && \
  go get -u -v github.com/cweill/gotests/...  && \
  go get -u -v golang.org/x/tools/cmd/guru  && \
  go get -u -v github.com/josharian/impl  && \
  go get -u -v github.com/haya14busa/goplay/cmd/goplay  && \
  go get -u -v github.com/uudashr/gopkgs/cmd/gopkgs  && \
  go get -u -v github.com/davidrjenni/reftools/cmd/fillstruct  && \
  curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(go env GOPATH)/bin v${GOLANGCI_LINT_VERSION} && \
  GO111MODULE=on go get golang.org/x/tools/gopls@latest && \
  go get -u -v github.com/go-delve/delve/cmd/dlv && \
  go get -u -v github.com/golang/protobuf/protoc-gen-go && \
  go get -u honnef.co/go/tools/... && \
  go get -u github.com/mgechev/revive

# Use this one to install the plugins etc.
COPY fonts /home/${user}/.local/share/.fonts
COPY dotfiles/zshrc /home/${user}/.zshrc
COPY dotfiles/p10k.zsh /home/${user}/.p10k.zsh
COPY dotfiles/Xdefaults /home/${user}/.Xdefaults
COPY dotfiles/alias.zsh /home/${user}/.oh-my-zsh/custom
COPY vim/vimrc /home/${user}/.vimrc
COPY vim/vimrc.local /home/${user}/.vimrc.local
COPY vim/vimrc.local.bundles /home/${user}/.vimrc.local.bundles

RUN curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim && \
  vim +PlugInstall +qall

RUN sudo chown -R ${user}:${user} . && \
  fc-cache -f && \
  /usr/bin/zsh -c 'source .zshrc'

COPY entrypoint.sh /entrypoint.sh

VOLUME [ "/code-server/extensions", "/code-server/user-data/User" ]

ENTRYPOINT [ "/entrypoint.sh" ]

CMD [ "/code-server/code-server", "--auth", "none", "--user-data-dir", "/code-server/user-data", "--host", "0.0.0.0", "--extensions-dir", "/code-server/extensions" ]
