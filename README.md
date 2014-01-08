procman
=======

Bash process manager

```sh
#!/bin/bash
. procman.sh

EXIT_MESSAGE="Sleeping finished."
EXIT_MESSAGE_INCOMPLETE="Sleeping exited."

for SLEEP in 1 5 2 3; do
  sleep $SLEEP &
  addScript "Sleep $SLEEP"
done

runStatusChecker
```

```sh
./sleep.sh
sleep 1: Complete
sleep 5: Complete
sleep 2: Complete
sleep 3: Complete
Sleeping finished.
```