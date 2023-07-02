# Dockerfile 依赖 https://github.com/jupyter/docker-stacks/blob/main/docker-stacks-foundation/Dockerfile
# Dockerfile 依赖 https://github.com/jupyter/docker-stacks/blob/main/base-notebook/Dockerfile
# Dockerfile form https://github.com/jupyter/docker-stacks/blob/main/minimal-notebook/Dockerfile

ARG ROOT_CONTAINER=ubuntu:22.04
FROM $ROOT_CONTAINER

LABEL maintainer="LCQ <lee-cq@qq.com>"

ARG NB_USER="jovyan"
ARG NB_UID="1000"
ARG NB_GID="100"

# Fix: https://github.com/hadolint/hadolint/wiki/DL4006
# Fix: https://github.com/koalaman/shellcheck/wiki/SC3014
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER root
ENV DEBIAN_FRONTEND noninteractive

# 安装操作系统方面的依赖
RUN apt-get update --yes && \
    apt-get install --yes --no-install-recommends \
    # FROM docker-stacks-foundation
    bzip2 \
    ca-certificates \
    locales \
    sudo \
    tini \
    wget \
    # FROM base-notebook https://github.com/jupyter/docker-stacks/blob/main/base-notebook/Dockerfile#L17
    fonts-liberation \
    pandoc \
    run-one \
    python3 python3-dev python3-pip \
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
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen

#  Configure environment
ENV SHELL=/bin/bash \
    NB_USER="${NB_USER}" \
    NB_UID=${NB_UID} \
    NB_GID=${NB_GID} \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8

# 复制一个脚本，我们将在运行某些命令后使用它来纠正权限
COPY --chmod=0750 fix-permissions /usr/local/bin/fix-permissions
RUN chmod a+rx /usr/local/bin/fix-permissions

# 在创建默认的NB_USER之前，在骨架.bashrc中启用提示颜色
# hadolint ignore=SC2016
RUN sed -i 's/^#force_color_prompt=yes/force_color_prompt=yes/' /etc/skel/.bashrc && \
    # Add call to conda init script see https://stackoverflow.com/a/58081608/4413446
    echo 'eval "$(command conda shell.bash hook 2> /dev/null)"' >> /etc/skel/.bashrc

# 在'users'组中创建名为jovyan用户的NB_USER, UID=1000，并确保这些dirs可被'users'组写入。
RUN echo "auth requisite pam_deny.so" >> /etc/pam.d/su && \
    sed -i.bak -e 's/^%admin/#%admin/' /etc/sudoers && \
    sed -i.bak -e 's/^%sudo/#%sudo/' /etc/sudoers && \
    useradd -l -m -s /bin/bash -N -u "${NB_UID}" "${NB_USER}" && \
    # mkdir -p "${CONDA_DIR}" && \
    # chown "${NB_USER}:${NB_GID}" "${CONDA_DIR}" && \
    chmod g+w /etc/passwd && \
    fix-permissions "${HOME}" 
    # fix-permissions "${CONDA_DIR}"

# Setup Python 3 environment
# 合并入 RUN APT-GET INSTALL
# Setup NodeJS

# Setup Golang
RUN curl -sSL https://golang.org/dl/go1.20.5.linux-amd64.tar.gz | tar -C /usr/local -xzf - && \
    ls -l /usr/local/go/bin && \
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile && \
    echo 'export GOROOT=/usr/local/go' >> /etc/profile && \
    echo 'export GOPATH=${HOME}/gopath' >> /etc/profile && \
    echo 'export PATH=$PATH:${HOME}/gopath/bin' >> /etc/profile

# Setup NodeJS
RUN curl -sSL https://nodejs.org/dist/v20.3.1/node-v20.3.1-linux-x64.tar.xz | tar -C /usr/local -xJf - && \
    ls -l /usr/local/node-v20.3.1-linux-x64/bin && \
    ln -s /usr/local/node-v20.3.1-linux-x64/ /usr/local/node && \
    echo 'export PATH=$PATH:/usr/local/node/bin' >> /etc/profile

# Switch back to jovyan to avoid accidental container runs as root
USER ${NB_UID}

# Setup Jupyter
RUN pip install --user \
    jupyter \
    jupyterlab \
    notebook \
    voila \
    jupyterlab-language-pack-zh-CN && \
    jupyter notebook --generate-config && \
    jupyter lab clean && \
    rm -rf "/home/${NB_USER}/.cache/yarn" 

ENV JUPYTER_PORT=8888
EXPOSE $JUPYTER_PORT

ENTRYPOINT ["tini", "-g", "--"]
CMD ["start-notebook.sh"]

# 尽可能晚地复制本地文件以避免缓存破坏
COPY start-notebook.sh start-singleuser.sh /usr/local/bin/
# 目前需要有jupyter_notebook_config和jupyter_server_config来支持经典和实验室
COPY jupyter_server_config.py docker_healthcheck.py /etc/jupyter/

USER root

# Legacy for Jupyter Notebook Server, see: [#1205](https://github.com/jupyter/docker-stacks/issues/1205)
RUN sed -re "s/c.ServerApp/c.NotebookApp/g" \
    /etc/jupyter/jupyter_server_config.py > /etc/jupyter/jupyter_notebook_config.py && \
    fix-permissions /etc/jupyter/

# 健康检查文档：https://docs.docker.com/engine/reference/builder/#healthcheck
# This healtcheck works well for `lab`, `notebook`, `nbclassic`, `server` and `retro` jupyter commands
# https://github.com/jupyter/docker-stacks/issues/915#issuecomment-1068528799
HEALTHCHECK --interval=5s --timeout=3s --start-period=5s --retries=3 \
    CMD /etc/jupyter/docker_healthcheck.py || exit 1


# 自定义配置
# Other dependencies
USER ${NB_UID}

WORKDIR "${HOME}"

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


