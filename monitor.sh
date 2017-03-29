#!/bin/bash

NAME=${NAME:?need process name}
PIDFILE=/var/run/$NAME/$NAME.pid
PID=$(cat $PIDFILE)

export PID
export NAME

check() {
  local proc
  proc=$1
  if [[ -f ~/run/$proc-$NAME.pid ]]; then
    local pid
    pid=$(cat ~/run/$proc-$NAME.pid)
    if [[ -n $pid ]]; then
      ps ajx | grep -v "grep" | grep $proc.sh | grep $pid
      [[ $? -eq 0 ]] && kill -9 $pid
    fi
  fi
}

run() {
  check gather
  bash gather.sh &
}

check monitor
echo $$ > ~/run/monitor-$NAME.pid

run

while true; do
  sleep 10s
  # check if PID modified
  CURR_PID=$(cat $PIDFILE)
  if [[ $PID != $CURR_PID ]]; then
    PID=$CURR_PID
    run
  fi
done