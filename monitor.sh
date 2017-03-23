#!/bin/bash

NAME=${NAME:?need process name}
PIDFILE=/var/run/$NAME/$NAME.pid
PID=$(cat $PIDFILE)

export PID

run_monitor() {
  if [[ -f ~/run/gather.pid ]]; then
    pid=$(cat ~/run/gather.pid)
    if [[ -n $pid ]]; then
      ps -u $(whoami) | grep gather.sh
      [[ $? -eq 0 ]] && kill -9 $pid
    fi
  fi
  bash gather.sh &
}

run_monitor

while true; do
  sleep 10s
  # check if PID modified
  [[ $PID != $(cat $PIDFILE) ]] && run_monitor
done