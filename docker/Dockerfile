# Dockerfile form https://github.com/jupyter/docker-stacks/blob/main/minimal-notebook/Dockerfile

ARG OWNER=jupyter
ARG BASE_CONTAINER=jupyter/base-notebook
FROM $BASE_CONTAINER

LABEL maintainer="LCQ <lee-cq@qq.com>"

# Fix: https://github.com/hadolint/hadolint/wiki/DL4006
# Fix: https://github.com/koalaman/shellcheck/wiki/SC3014
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER root

RUN apt-get update --yes && \
    apt-get install --yes --no-install-recommends \
    # Common useful utilities
    curl \
    git \
    tzdata \
    unzip \
    vim-tiny \
    # git-over-ssh
    openssh-client \
    # less is needed to run help in R
    # see: https://github.com/jupyter/docker-stacks/issues/1588
    less \
    # nbconvert dependencies
    # https://nbconvert.readthedocs.io/en/latest/install.html#installing-tex
    texlive-xetex \
    texlive-fonts-recommended \
    texlive-plain-generic \
    # Enable clipboard on Linux host systems
    xclip && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Setup Golang
RUN curl -sSL https://golang.org/dl/go1.20.5.linux-amd64.tar.gz | tar -C /usr/local -xzf - && \
    ls -l /usr/local/go/bin && \
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile && \
    echo 'export GOROOT=/usr/local/go' >> /etc/profile && \
    echo 'export GOPATH=${HOME}/gopath' >> /etc/profile && \
    echo 'export PATH=$PATH:${HOME}/gopath/bin' >> /etc/profile
    

# Switch back to jovyan to avoid accidental container runs as root
USER ${NB_UID}

# Add R mimetype option to specify how the plot returns from R to the browser
COPY --chown=${NB_UID}:${NB_GID} Rprofile.site /opt/conda/lib/R/etc/

# 配置pip settings
# RUN pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple

# Setup Jupyter Go kernel
RUN source /etc/profile && \
    go install github.com/gopherdata/gophernotes@v0.7.5 && \
    mkdir -p ~/.local/share/jupyter/kernels/gophernotes && \
    cd ~/.local/share/jupyter/kernels/gophernotes && \
    cp "$(go env GOPATH)"/pkg/mod/github.com/gopherdata/gophernotes@v0.7.5/kernel/*  "." && \
    # in case copied kernel.json has no write permission 
    chmod +w ./kernel.json && \
    sed "s|gophernotes|$(go env GOPATH)/bin/gophernotes|" < kernel.json.in > kernel.json

# Setup Jupyter JavaScript kernel
RUN source /etc/profile && \
    npm install -g --unsafe-perm ijavascript && \
    ijsinstall 
