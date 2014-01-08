#!/bin/bash

. procman.sh

SLEEPS="1 5 2 3"
EXIT_MESSAGE="Sleeping complete."
EXIT_MESSAGE_INCOMPLETE="Sleeping exited."

for SLEEP in $SLEEPS; do
  sleep $SLEEP &
  addScript "sleep $SLEEP"
done

runStatusChecker
