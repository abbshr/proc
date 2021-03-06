#!/bin/bash

echo $$ > ~/run/gather-$NAME.pid

PID=${PID:-$$}
PROC=/proc/$PID

COLLECTOR_ADDR="http://192.168.13.157:8080"
REPORT_TEMPLATE='{ "timestamp": %d, "rss": %.3f, "read_bytes": %d, "write_bytes": %d, "cpu_usage": %.1f }'
REPORT_HEADER="Content-Type: application/json"
REPORT_URL=$COLLECTOR_ADDR/
FREQUENCY=1s

declare -i PAGE_SIZE
PAGE_SIZE=$(getconf PAGE_SIZE)

declare -i PROCESSORS
declare -i TOTAL_CPUTIME
declare -i CPUTIME

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
  echo $sum
}

# utime stime cutime cstime (jiffies)
cpustat() {
  local raw=($(cat $PROC/stat))
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
  bc -l <<< "scale=3; ($curr_cputime - $CPUTIME)  * 100 / ($curr_total_cputime - $TOTAL_CPUTIME)"
  CPUTIME=$curr_cputime
  TOTAL_CPUTIME=$curr_total_cputime
}

# ret: rss (MB)
rss_page() {
  cat $PROC/statm | cut -d" " -f2
}

rss_bytes() {
  read pages
  echo $(( $pages * $PAGE_SIZE ))
}

rss_mbytes() {
  read pages
  bc -l <<< "scale=3; $pages * $PAGE_SIZE / 1024 / 1024"
}

rss() {
  rss_page | rss_mbytes
}

# ret <Array>: read write (B)
io() {
  cat $PROC/io | grep "^read_bytes\|^write_bytes" | cut -d":" -f2 | xargs echo
}

systime() {
  date +%s%3N
}

gather_facts() {
  printf "$REPORT_TEMPLATE" $(systime) $(rss) $(io) $(cpu)
}

report() {
  read body
  echo $body >> ~/data/alarm-system/$NAME.dump
  # curl -X POST -H "$REPORT_HEADER" -d "$body" $REPORT_URL
}

PROCESSORS=$(processors)
TOTAL_CPUTIME=$(totalcputime)
CPUTIME=$(cputime)

while true; do
  sleep $FREQUENCY
  gather_facts | report
done