#!/bin/env bash

cd $(dirname $0)
WORKDIR=$(pwd)
export WORKDIR

DOCKER_IMAGE_NAME=${DOCKER_IMAGE_NAME:-leecq/jupyter}
DOCKER_IMAGE_TAG=${DOCKER_IMAGE_TAG:-latest}
CONTAILER_NAME=${CONTAILER_NAME:-jupyter}

if witch docker ;then 
  echo "需要安装Docker ..."
  exit 1
fi

# if witch docker-compose ; then
#   echo "需要安装docker-compose ..."
#   exit 1
# fi

function build {
  # 构建镜像
  cd build

  echo "正在构建镜像 ->${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}  "
  docker build -t "${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}" .

  cd $WORKDIR
}

function run {
  # 创建一个全新的容器
  docker run --name "${CONTAILER_NAME}" -d \
    -v ${WORKDIR}/jupyters:/home/jc \
    -p 38888:8888 \
    ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}
}

function start {
  # 启动容器
  if docker ps -a --format {{.Names}} |grep -q ${CONTAILER_NAME}; then
    # 如果已经存在容器
    docker start 
  else
    run
  fi

}

function stop {
  # 停止容器
  docker stop ${CONTAILER_NAME}
}

function rm {
  # 删除容器
  docker rm ${CONTAILER_NAME}
}

case $1 in
build ) build ;;
run ) run ;;
start ) start ;;
stop ) stop ;;
rm ) rm ;;
esac