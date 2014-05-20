#!/bin/bash
exec 2> /dev/null

SCRIPTS=()
STATUSES=()
PROCESSES=()
ALL_DONE=0

addScript() {
  SCRIPTS+=("$1")
  PROCESSES+=($!)
  STATUSES+=("Started")
}

checkStatus() {
  ALL_DONE=1
  for ((i=0; i < ${#SCRIPTS[@]}; i++)); do
    if [ `kill -0 ${PROCESSES[$i]} 2>&1 | wc -l` -eq "0" ]; then
      STATUSES[$i]="Running"
      ALL_DONE=0
    else
      STATUSES[$i]="Complete"
    fi
  done
}

runStatusChecker() {
  trap "shutDown" EXIT
  outputStatus
  while [ $ALL_DONE -eq "0" ]; do
    sleep 1
    checkStatus
    clearStatus
    outputStatus
  done
}

outputStatus() {
  for ((i=0; i < ${#SCRIPTS[@]}; i++)); do
    echo -e "\033[K${SCRIPTS[$i]}: ${STATUSES[$i]}"
  done
}
clearStatus() {
  echo -en "\033[G\033[${#SCRIPTS[@]}A\033[K"
}

shutDown() {
  checkStatus
  if [ $ALL_DONE -eq "0" ]; then
    killAll
    sleep 1
    for ((i=0; i < ${#SCRIPTS[@]}; i++)); do
      if [ ${STATUSES[$i]} == "Running" ]; then
        if [ `kill -0 ${PROCESSES[$i]} 2>&1 | wc -l` -eq "0" ]; then
          STATUSES[$i]="Unable to kill"
        else
          STATUSES[$i]="Killed"
        fi
      fi
    done
    clearStatus
    outputStatus
    echo "$EXIT_MESSAGE_INCOMPLETE"
  else
    echo "$EXIT_MESSAGE"
  fi
}

killAll() {
  for ((i=0; i < ${#SCRIPTS[@]}; i++)); do
    if [ `kill -0 ${PROCESSES[$i]} 2>&1 | wc -l` -eq "0" ]; then
      killTree ${PROCESSES[$i]}
    fi
  done
}

killTree() {
  local _pid=$1
  local _sig=${2:-SIGKILL}
  kill -stop ${_pid}
  for _child in $(ps -o pid --no-headers --ppid ${_pid}); do
    killTree ${_child} ${_sig}
  done
  kill -${_sig} ${_pid}
}
