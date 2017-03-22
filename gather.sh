#!/bin/bash

PID=${PID:-$$}
PROC=/proc/$PID

COLLECTOR_ADDR="http://192.168.13.157:8080"
REPORT_TEMPLATE='{ "timestamp": %d, "rss": %d, "read_bytes": %d, "write_bytes": %d, "cpu_usage": %d }'
REPORT_HEADER="Content-Type: application/json"
REPORT_URL=$COLLECTOR_ADDR/
FREQUENCY=1s

declare -i PROCESSORS
declare -i TOTAL_CPUTIME
declare -i CPUTIME
PROCESSORS=$(processors)
TOTAL_CPUTIME=$(totalcputime)
CPUTIME=$(cputime)

# total memory (KB)
total_memory() {
  cat /proc/meminfo | grep "MemTotal" | cut -d":" -f2 | xargs echo | cut -d" " -f1
}

processors() {
  cat /proc/cpuinfo | grep "siblings" | wc -l
}

# utime nice systime idle iowait irq softirq steal guest guest_nice (jiffies)
totalcpustat() {
  local raw=($(head -n1 /proc/stat))
  echo ${raw[@]:1}
}

accumulate() {
  read -a arr
  local -i sum
  for t in ${arr[@]}; do
    sum+=$t
  done
  echo sum
}

# utime stime cutime cstime (jiffies)
cpustat() {
  local raw=$(cat $PROC/stat)
  echo ${raw[*]:13:4}
}

totalcputime() {
  totalcpustat | accumulate
}

cputime() {
  cpustat | accumulate
}

cpu() {
  local -i curr_cputime
  local -i curr_total_cputime
  curr_cputime=$(cputime)
  curr_total_cputime=$(totalcputime)
  echo $(( ($curr_cputime - $CPUTIME) * $PROCESSORS / ($curr_total_cputime - $TOTAL_CPUTIME) ))
  CPUTIME=$curr_cputime
  TOTAL_CPUTIME=$curr_total_cputime
}

# ret: rss (KB)
rss() {
  cat $PROC/status | grep "VmRSS" | cut -d":" -f2 | xargs echo | cut -d" " -f1
}

# ret <Array>: read write (B)
io() {
  cat $PROC/io | grep "^read_bytes\|^write_bytes" | cut -d":" -f2 | xargs echo
}

systime() {
  # TODO
  date
}

gather_facts() {
  printf "$REPORT_TEMPLATE" $(systime) $(rss) $(io) $(cpu)
}

report() {
  read body
  curl -X POST -H "$REPORT_HEADER" -d "$body" $REPORT_URL
}

while true; do
  sleep $FREQUENCY
  gather_facts | report
done