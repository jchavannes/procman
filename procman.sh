#!/bin/bash

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
  trap "killAll" EXIT
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

killAll() {
  checkStatus
  if [ $ALL_DONE -eq "0" ]; then
    for ((i=0; i < ${#SCRIPTS[@]}; i++)); do
      if [ `kill -0 ${PROCESSES[$i]} 2>&1 | wc -l` -eq "0" ]; then
        kill -SIGKILL ${PROCESSES[$i]}
        sleep 0.15
        if [ `kill -0 ${PROCESSES[$i]} 2>&1 | wc -l` -eq "0" ]; then
          STATUSES[$i]="Unable to kill"
        else
          STATUSES[$i]="Killed"
        fi
      elif [ "${STATUSES[$i]}" != "Complete" ]; then
        # Weird state where it was running when checkStatus was ran, but finished while killing other scripts
        STATUSES[$i]="Completed while killing"
      fi
    done > /dev/null 2>&1
    clearStatus
    outputStatus
    echo -n "$EXIT_MESSAGE_INCOMPLETE"
  else
    echo "$EXIT_MESSAGE"
  fi
}
