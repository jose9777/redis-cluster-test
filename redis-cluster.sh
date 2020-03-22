#!/bin/bash
# jose

work_dir=$0
work_dir=`pwd`

function  start_redis_cluster() {
  echo -e "\033[1;32m[INFO] bring up redis-cluster \033[0m"
  local start=7000
  while [[ $start -le 7005 ]]; do
    ((start++))
    local dir=$work_dir/redis-$start
    if [[ -f $dir/run.pid ]]; then
      echo -e "\033[1;32m[INFO] saw redis-server $start \033[0m"
      continue
    fi
    echo -e "\033[1;32m[INFO] bring up redis-server $start \033[0m"
    cd $dir && (nohup  redis-server redis.conf &> output.log & echo $! > run.pid)

  done
  echo -e "\033[1;32m[INFO] you have redis-cluster now \033[0m"
}

function redis_cluster_init() {
  if [[ -f $work_dir/redis_inited ]]; then
    echo "initialized before"
    return
  fi
  sleep 5
  redis-cli --cluster create 127.0.0.1:7006 127.0.0.1:7001 \
  127.0.0.1:7002 127.0.0.1:7003 127.0.0.1:7004 127.0.0.1:7005 \
  --cluster-replicas 1

  echo "initialized finished"
  echo "done" > $work_dir/redis_inited
}

function stop_redis_cluster() {
  echo -e "\033[1;32m[INFO] stoping redis-cluster \033[0m"
  local start=7000
  while [[ $start -le 7005 ]]; do
    ((start++))
    local filePath=$work_dir/redis-$start/run.pid
    if [[ ! -f $filePath ]]; then
      continue
    fi
    pid=`cat $filePath`
    echo -e "\033[1;32m[INFO] stopping redis-server $start pid: $pid \033[0m"
    _kill $pid
    rm $filePath
  done
  echo -e "\033[1;32m[INFO] redis-cluster stoped \033[0m"
}

function clear_redis_cluster() {
  local start=7000
  while [[ start -le 7005 ]]; do
    ((start++))
    local dir=$work_dir/redis-$start
    _rm $dir/dump.rdb
    _rm $dir/output.log
    _rm $dir/appendonly.aof
    _rm $dir/nodes.conf
  done

  _rm redis_inited
}

function _rm() {
  if [[ -f $1 ]]; then
    rm $1
  fi
}

function _kill() {
  local pid=$1
  if [[ "" != $pid ]]; then
    kill -9 $pid
  fi
}

function info() {
  echo -e "\033[1;32m[INFO] usage: ./redis-cluster start|stop \033[0m"
}

operate=$1

case $operate in
  start )
    start_redis_cluster
    redis_cluster_init
    ;;
  stop )
    stop_redis_cluster
  ;;
  clear )
  stop_redis_cluster
  clear_redis_cluster
  ;;
  * )
  info
  ;;
esac


#  nohup redis-server redis-7001/redis.conf&> redis-7001/output.log & echo $! > redis-7001/run.pid
# nohup redis-server $work_dir/redis-7001/redis.conf &> $work_dir/redis-7001/output.log & echo $1 > $work_dir/
