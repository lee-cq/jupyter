#!/bin/env bash

cd $(dirname $0)
WORKDIR=$(pwd)
export WORKDIR

# 加载 .env 文件
if [ -f .env ]; then
  export $(cat .env | grep -v ^# | xargs)
fi

JP_IMAGE_NAME=${JP_IMAGE_NAME:-leecq/jupyter}
JP_IMAGE_TAG=${JP_IMAGE_TAG:-latest}

JP_CONTAILER_NAME=${JP_CONTAILER_NAME:-jupyter}
JP_CONTAILER_UID=${JP_CONTAILER_UID:-$(id -u)}

JP_HOSTNAME=${JP_HOSTNAME:-$(hostname)}
JP_HOST_PORT=${JP_HOST_PORT:-38888}

if ! command -v docker > /dev/null ;then 
  echo "需要安装Docker ..."
  exit 1
fi

# 检查是否有docker权限
if ! docker ps > /dev/null ;then
  echo "没有Docker权限，请使用sudo运行; 或者将当前用户加入docker组(Synology root 组)"
  echo "Linux 下使用命令：sudo usermod -aG docker $USER"
  echo "Synology 下使用命令：sudo synogroup --member $USER root"
  exit 1
fi

function build {
  # 构建镜像
  cd docker

  echo "正在构建镜像 ->${JP_IMAGE_NAME}:${JP_IMAGE_TAG}  "
  docker build "$@" -t "${JP_IMAGE_NAME}:${JP_IMAGE_TAG}" .

  cd $WORKDIR
}

function jp_host_port {
  # 获取容器的端口号
  echo "正在获取 JupyterLab 端口号 ... "
  PORT=$(docker ps -a --format "{{.Names}} {{.Ports}}" |grep ${JP_CONTAILER_NAME} |awk -F '->' '{print $1}' |awk -F ':' '{print $NF}' | tail -n 1)
  if [ -z "${PORT}" ]; then
    echo "获取 JupyterLab 端口号 失败"
    exit 1
  fi
  echo ${PORT}
}

function run {
  # 创建一个全新的容器 $1 local port
  set -e
  local port=${1}
  echo "正在启动容器 ->${JP_CONTAILER_NAME}  "
  docker run --name "${JP_CONTAILER_NAME}" -d \
    -u ${JP_CONTAILER_UID} \
    -v ${WORKDIR}/jupyters:/home/jovyan/work \
    -p ${port:-${JP_HOST_PORT}}:8888 \
    ${JP_IMAGE_NAME}:${JP_IMAGE_TAG}
  
  sleep 3
  echo "容器启动成功，端口号：$(jp_host_port)，token：$(token)"
  status
  set +e
}

function token {
  # 获取容器的token
  echo "正在获取 JupyterLab token ... "
  TOKEN=$(docker logs ${JP_CONTAILER_NAME} 2>&1 |grep "token=" |awk -F 'token=' '{print $NF}' |tail -n 1)
  if [ -z "${TOKEN}" ]; then
    echo "获取 JupyterLab token 失败"
    exit 1
  fi
  echo token is ${TOKEN}
  echo "尝试直接访问： http://${JP_HOSTNAME}:${JP_HOST_PORT}/lab?token=${TOKEN}"
}

function start {
  # 启动容器
  if docker ps -a --format {{.Names}} |grep -q ${JP_CONTAILER_NAME}; then
    # 如果已经存在容器
    docker start ${JP_CONTAILER_NAME} "$@" && echo Started ${JP_CONTAILER_NAME} ...
  else
    # 如果不存在容器
    echo "容器不存在，正在创建容器 ..."
    run "$@"
  fi
}

function stop {
  # 停止容器
  docker stop ${JP_CONTAILER_NAME} "$@" && echo Stoped ${JP_CONTAILER_NAME} ...
  status "$@"
}

function rm {
  # 删除容器
  docker rm ${JP_CONTAILER_NAME} "$@" && echo Removed ${JP_CONTAILER_NAME} ...
}

function status {
  # 查看容器状态
  docker ps -a "$@" |grep ${JP_CONTAILER_NAME}
}


action=$1
shift

case $action in
build ) build  "$@" ;;
run )   run    "$@" ;;
token ) token  "$@" ;;
status ) status "$@" ;;
start ) start  "$@" ;;
stop ) stop    "$@" ;;
rm ) rm        "$@" ;;
logs ) docker logs ${JP_CONTAILER_NAME} "$@" ;;
* ) echo "Usage: $0 {build|run|token|status|start|stop|rm|logs}" ;;
esac