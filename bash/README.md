procman
=======

Bash (or PHP) process manager

**- Example Bash script**
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
Sleep 1: Complete
Sleep 5: Complete
Sleep 2: Complete
Sleep 3: Complete
Sleeping finished.
```
