#!/bin/env bash

cd $(dirname $0)
WORKDIR=$(pwd)
export WORKDIR

JP_IMAGE_NAME=${JP_IMAGE_NAME:-leecq/jupyter}
JP_IMAGE_TAG=${JP_IMAGE_TAG:-latest}

JP_CONTAILER_NAME=${JP_CONTAILER_NAME:-jupyter}
JP_CONTAILER_PORT=${JP_CONTAILER_PORT:-38888}
JP_HOSTNAME=${JP_HOSTNAME:-$(hostname)}

if ! command -v docker > /dev/null ;then 
  echo "需要安装Docker ..."
  exit 1
fi

function build {
  # 构建镜像
  cd docker

  echo "正在构建镜像 ->${JP_IMAGE_NAME}:${JP_IMAGE_TAG}  "
  docker build -t "${JP_IMAGE_NAME}:${JP_IMAGE_TAG}" .

  cd $WORKDIR
}

function run {
  # 创建一个全新的容器 $1 local port
  set -e
  local port=${1}
  echo "正在启动容器 ->${JP_CONTAILER_NAME}  "
  docker run --name "${JP_CONTAILER_NAME}" -d \
    -v ${WORKDIR}/jupyters:/home/work \
    -p ${port:-${JP_CONTAILER_PORT}}:8888 \
    ${JP_IMAGE_NAME}:${JP_IMAGE_TAG}
  
  sleep 3
  echo "容器启动成功，端口号：${port:-${JP_CONTAILER_PORT}}，token：$(token)"
  status
  set +e
}

function token {
  # 获取容器的token
  echo "正在获取 JupyterLab token ... "
  TOKEN=$(docker logs ${JP_CONTAILER_NAME} 2>&1 |grep "token=" |awk -F 'token=' '{print $NF}')
  if [ -z "${TOKEN}" ]; then
    echo "获取 JupyterLab token 失败"
    exit 1
  fi
  echo ${TOKEN}
}

function start {
  # 启动容器
  if docker ps -a --format {{.Names}} |grep -q ${JP_CONTAILER_NAME}; then
    # 如果已经存在容器
    docker start ${JP_CONTAILER_NAME}
  else
    run
  fi
}

function stop {
  # 停止容器
  docker stop ${JP_CONTAILER_NAME} && echo Stoped ${JP_CONTAILER_NAME} ...
  status
}

function rm {
  # 删除容器
  docker rm ${JP_CONTAILER_NAME} && echo Removed ${JP_CONTAILER_NAME} ...
}

function status {
  # 查看容器状态
  docker ps -a  |grep ${JP_CONTAILER_NAME}
}

case $1 in
build ) build  "$@" ;;
run )   run    "$@" ;;
token ) token  "$@" ;;
status ) status "$@" ;;
start ) start  "$@" ;;
stop ) stop    "$@" ;;
rm ) rm        "$@" ;;
* ) echo "Usage: $0 {build|run|token|status|start|stop|rm}" ;;
esac