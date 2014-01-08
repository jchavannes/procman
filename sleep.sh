#!/bin/bash
. procman.sh

EXIT_MESSAGE="Sleeping complete."
EXIT_MESSAGE_INCOMPLETE="Sleeping exited."

for SLEEP in 1 5 2 3; do
  sleep $SLEEP &
  addScript "Sleep $SLEEP"
done

runStatusChecker
