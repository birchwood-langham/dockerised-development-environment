FROM birchwoodlangham/ubuntu-base-code:latest

ARG password
ARG user

RUN apt-get update && apt-get upgrade -y && \
  apt-get install -y -qq --fix-missing sudo zsh zsh-syntax-highlighting zplug zsh-theme-powerlevel9k fonts-powerline \
  openjdk-11-jdk go-dep build-essential locales apt-transport-https ca-certificates gnupg-agent \
  software-properties-common httpie unzip gosu git-flow && \
  locale-gen en_US.UTF-8

# Setup user
RUN  useradd -d /home/${user} -m -U ${user} -G sudo -s /usr/bin/zsh && \
  echo "${password}" | chpasswd

# Install Go globally and link to /usr/lib/go for compatibility with Arch host
RUN wget https://dl.google.com/go/go1.13.4.linux-amd64.tar.gz && \
  tar -C /usr/local -xzf go1.13.4.linux-amd64.tar.gz && \
  rm go1.13.4.linux-amd64.tar.gz && \
  ln -s /usr/local/go /usr/lib/go

# Install SBT and Scala
RUN wget https://dl.bintray.com/sbt/debian/sbt-1.3.4.deb && \
  wget http://downloads.lightbend.com/scala/2.13.1/scala-2.13.1.deb && \
  dpkg -i sbt-1.3.4.deb && \
  dpkg -i scala-2.13.1.deb && \
  rm *.deb    

# Install Docker 
RUN curl https://get.docker.com | bash && \ 
  apt-get -y install docker-compose && \
  usermod -aG docker ${user}

# Install protoc
RUN PROTOC_ZIP=protoc-3.11.0-linux-x86_64.zip &&\
  curl -OL https://github.com/protocolbuffers/protobuf/releases/download/v3.11.0/$PROTOC_ZIP  &&\
  unzip -o $PROTOC_ZIP -d /usr/local bin/protoc  &&\
  rm -f $PROTOC_ZIP

# Install Kubernetes
RUN curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
  echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" >/etc/apt/sources.list.d/kubernetes.list && \
  apt-get update && \
  apt-get install -y kubectl

# Install Helm
RUN wget https://get.helm.sh/helm-v3.0.0-linux-amd64.tar.gz && \
  tar xzf helm-v3.0.0-linux-amd64.tar.gz && \
  mv linux-amd64/helm /usr/local/bin/ && \
  rm -f helm-v3.0.0-linux-amd64.tar.gz &&\
  rm -fr linux-amd64

# Install Nodejs and Yarn
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - && \
  curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
  echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
  apt-get update && \
  apt-get install -y nodejs && \
  apt-get install yarn

ENV CT_VERSION=2.3.3

RUN mkdir /ct && cd /ct && \ 
  curl -Lo chart-testing_${CT_VERSION}_linux_amd64.tar.gz https://github.com/helm/chart-testing/releases/download/v${CT_VERSION}/chart-testing_${CT_VERSION}_linux_amd64.tar.gz  && \
  tar xzf chart-testing_${CT_VERSION}_linux_amd64.tar.gz  && \
  chmod +x ct && sudo mv ct /usr/local/bin/  && \
  mv etc /etc/ct && \
  cd / && rm -fr /ct

RUN mkdir -p /opt/idea && \
  wget https://download.jetbrains.com/idea/ideaIU-2019.2.4-no-jbr.tar.gz && \
  tar -C /opt/idea -zxf ideaIU-2019.2.4-no-jbr.tar.gz --strip-components=1 && \
  rm ideaIU-2019.2.4-no-jbr.tar.gz && \
  ln -s /opt/idea/bin/idea.sh /usr/local/bin/idea.sh

# Install Postman
RUN wget https://dl.pstmn.io/download/latest/linux64 -O Postman-linux.tar.gz && \
  tar -C /opt -xf Postman-linux.tar.gz && \
  ln -s /opt/Postman/Postman /usr/local/bin/Postman && \
  rm Postman-linux.tar.gz

# Clean up apt
RUN apt-get autoremove -y -qq && \
  apt-get clean && rm -rf /var/lib/apt/lists/*

USER ${user}
WORKDIR /home/${user}

# Install Oh My Zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" && \
  git clone https://github.com/bhilburn/powerlevel9k.git ~/.oh-my-zsh/custom/themes/powerlevel9k

ENV GOPATH=/home/${user}/go
ENV CARGO_PATH=/home/${user}/.cargo
ENV PATH=$PATH:/usr/local/go/bin:$GOPATH/bin:$CARGO_PATH/bin

# Set up Rust in the user environment    
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
  /home/${user}/.cargo/bin/rustup component add clippy llvm-tools-preview rls rust-analysis rustfmt rust-src

# Install Miniconda for Python environments
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
  sh Miniconda3-latest-Linux-x86_64.sh -b && \
  rm Miniconda3-latest-Linux-x86_64.sh

# # We are going to expose the Code configuration files in the .code folder under the user directory as it's easier to remember
# # so we need to create a symlink to the actual configuration folder
# RUN mkdir -p /home/${user}/.config/Code && \  
#     ln -s /home/${user}/.config/Code /home/${user}/.code

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
  go get -u -v github.com/alecthomas/gometalinter  && \
  gometalinter --install  && \
  go get -u -v github.com/go-delve/delve/cmd/dlv && \
  go get -u -v github.com/golang/protobuf/protoc-gen-go

# Install the vscode plugins
RUN code --install-extension ms-vscode.go --force && \
  code --install-extension grapecity.gc-excelviewer --force && \
  code --install-extension codezombiech.gitignore --force && \
  code --install-extension eamodio.gitlens --force && \
  code --install-extension ms-vsliveshare.vsliveshare-pack --force && \
  code --install-extension bat67.markdown-extension-pack --force && \
  code --install-extension serge.vsc-material-theme-italicize --force && \
  code --install-extension jebbs.plantuml --force && \
  code --install-extension ckolkman.vscode-postgres --force && \
  code --install-extension alefragnani.project-manager --force && \
  code --install-extension mechatroner.rainbow-csv --force && \
  code --install-extension swellaby.rust-pack --force && \
  code --install-extension andyyaldoo.vscode-json --force && \
  code --install-extension zxh404.vscode-proto3 --force && \
  code --install-extension dotjoshjohnson.xml --force && \
  code --install-extension redhat.vscode-yaml --force && \
  code --install-extension donjayamanne.python-extension-pack --force && \
  code --install-extension nodesource.vscode-for-node-js-development-pack --force

# Use this one to install the plugins etc.
COPY fonts /home/${user}/.fonts
COPY zshrc /home/${user}/.zshrc
COPY Xdefaults /home/${user}/.Xdefaults

USER root

COPY entrypoint.sh /entrypoint.sh

RUN sed -i 's|USER_NAME|'${user}'|g' /entrypoint.sh

VOLUME ["/home/${user}/go", "/home/${user}/.config", "/home/${user}/.ssh", "/home/${user}/.IntelliJIdea2019.2"]

ENTRYPOINT [ "/entrypoint.sh" ]

# CMD [ "/usr/bin/code", "--verbose", "--disable-gpu" ]
CMD [ "zsh" ]
