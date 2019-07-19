FROM birchwoodlangham/ubuntu-base-code:latest

ARG password
ARG user

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y -qq --fix-missing sudo zsh zsh-syntax-highlighting zplug zsh-theme-powerlevel9k fonts-powerline \
    openjdk-11-jdk go-dep build-essential locales apt-transport-https ca-certificates gnupg-agent \
    software-properties-common httpie unzip && \
    locale-gen en_US.UTF-8

# Setup user
RUN  useradd -d /home/${user} -m -U ${user} -G sudo -s /usr/bin/zsh && \
    echo "${password}" | chpasswd

# Install Go globally
RUN wget https://dl.google.com/go/go1.12.7.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.12.7.linux-amd64.tar.gz && \
    rm go1.12.7.linux-amd64.tar.gz

# Install SBT and Scala
RUN wget https://dl.bintray.com/sbt/debian/sbt-1.2.8.deb && \
    wget http://downloads.lightbend.com/scala/2.12.8/scala-2.12.8.deb && \
    dpkg -i sbt-1.2.8.deb && \
    dpkg -i scala-2.12.8.deb && \
    rm *.deb    

# Install Docker 
RUN curl https://get.docker.com | bash && \ 
    apt-get -y install docker-compose 
#    usermod -aG docker tanq

# Install protoc
RUN PROTOC_ZIP=protoc-3.6.1-linux-x86_64.zip &&\
    curl -OL https://github.com/google/protobuf/releases/download/v3.6.1/$PROTOC_ZIP  &&\
    unzip -o $PROTOC_ZIP -d /usr/local bin/protoc  &&\
    rm -f $PROTOC_ZIP

# Install Kubernetes
RUN curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
    echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" >/etc/apt/sources.list.d/kubernetes.list && \
    apt-get update && \
    apt-get install -y kubectl

# Install Helm
RUN wget https://storage.googleapis.com/kubernetes-helm/helm-v2.14.1-linux-amd64.tar.gz && \
    tar xzf helm-v2.14.1-linux-amd64.tar.gz && \
    mv linux-amd64/helm /usr/local/bin/ && \
    rm -f helm-v2.14.1-linux-amd64.tar.gz &&\
    rm -fr linux-amd64

ENV CT_VERSION=2.3.3

RUN mkdir /ct && cd /ct && \ 
    curl -Lo chart-testing_${CT_VERSION}_linux_amd64.tar.gz https://github.com/helm/chart-testing/releases/download/v${CT_VERSION}/chart-testing_${CT_VERSION}_linux_amd64.tar.gz  && \
    tar xzf chart-testing_${CT_VERSION}_linux_amd64.tar.gz  && \
    chmod +x ct && sudo mv ct /usr/local/bin/  && \
    mv etc /etc/ct && \
    cd / && rm -fr /ct

# Clean up apt
RUN apt-get autoremove -y -qq && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh

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
    code --install-extension donjayamanne.python-extension-pack --force

# Use this one to install the plugins etc.
COPY fonts /home/${user}/.fonts
COPY zshrc /home/${user}/.zshrc

VOLUME ["/home/${user}/go", "/home/${user}/.config", "/home/${user}/.ssh"]

ENTRYPOINT [ "/entrypoint.sh" ]

CMD [ "/usr/bin/code", "--verbose", "--disable-gpu" ]
