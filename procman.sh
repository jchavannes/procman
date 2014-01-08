#!/bin/bash

SCRIPTS=""
STATUSES=()
PROCESSES=()
ALL_DONE=0

addScript() {
  SCRIPTS="$SCRIPTS $1"
  STATUSES[$1]="Started"
  PROCESSES[$1]=$!
}

checkStatus() {
  ALL_DONE=1
  for SCRIPT in $SCRIPTS; do
    if [ `kill -0 ${PROCESSES[$SCRIPT]} 2>&1 | wc -l` -eq "0" ]; then
      STATUSES[$SCRIPT]="Running"
      ALL_DONE=0
    else
      STATUSES[$SCRIPT]="Complete"
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
  for SCRIPT in $SCRIPTS; do
    echo -e "\033[K$SCRIPT: ${STATUSES[$SCRIPT]}"
  done
}
clearStatus() {
  echo -en "\033[G\033[${#STATUSES[@]}A\033[K"
}

killAll() {
  checkStatus
  if [ $ALL_DONE -eq "0" ]; then
    for SCRIPT in $SCRIPTS; do
      if [ `kill -0 ${PROCESSES[$SCRIPT]} 2>&1 | wc -l` -eq "0" ]; then
        kill -SIGKILL ${PROCESSES[$SCRIPT]}
        if [ `kill -0 ${PROCESSES[$SCRIPT]} 2>&1 | wc -l` -eq "0" ]; then
          STATUSES[$SCRIPT]="Unable to kill"
        else
          STATUSES[$SCRIPT]="Killed"
        fi
      elif [ "${STATUSES[$SCRIPT]}" != "Complete" ]; then
        # Weird state where it was running when checkStatus was ran, but finished while killing other scripts
        STATUSES[$SCRIPT]="Completed while killing"
      fi
    done > /dev/null 2>&1
    clearStatus
    outputStatus
    echo "$EXIT_MESSAGE_INCOMPLETE"
  else
    echo "$EXIT_MESSAGE"
  fi
}
