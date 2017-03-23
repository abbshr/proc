#!/bin/bash

NAME=${NAME:?need process name}
PIDFILE=/var/run/$NAME/$NAME.pid
PID=$(cat $PIDFILE)

export PID
export NAME

run_check() {
  if [[ -f ~/run/monitor-$NAME.pid ]]; then
    local pid
    pid=$(cat ~/run/monitor-$NAME.pid)
    if [[ -n $pid ]]; then
      ps -ajx | grep monitor.sh | grep $pid
      [[ $? -eq 0 ]] && kill -9 $pid
    fi
  fi
  echo $$ > ~/run/monitor-$NAME.pid
}

run_monitor() {
  if [[ -f ~/run/gather-$NAME.pid ]]; then
    local pid
    pid=$(cat ~/run/gather-$NAME.pid)
    if [[ -n $pid ]]; then
      ps -ajx | grep gather.sh | grep $pid
      [[ $? -eq 0 ]] && kill -9 $pid
    fi
  fi
  bash gather.sh &
}

run_check
run_monitor

while true; do
  sleep 10s
  # check if PID modified
  [[ $PID != $(cat $PIDFILE) ]] && run_monitor
done