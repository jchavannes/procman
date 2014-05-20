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

**- Example PHP script**
```php
<?
include("procman.php");

CONST POOL = "sleep";

for ($i = 1; $i <= 5; $i++) {
    $command = "sleep $i";
    ProcessManager::addThread($command, "Sleep $i", POOL);
}

for ($finished = false; !$finished; sleep(1)) {
    $finished = true;
    CLI::cursorBack();
    /** @var $thread ProcessThread */
    foreach (ProcessManager::$processThreads[POOL] as $name => $thread) {
        $thread->update();
        if ($thread->error || $thread->exit_code) {
            $message = $thread->error ? $thread->error : "Error encountered in thread";
            ProcessManager::flushThreads(POOL);
            throw new Exception($message);
        }
        else if (!$thread->done) {
            CLI::doOutput("$name: Running");
            $finished = false;
        }
        else {
            CLI::doOutput("$name: Complete");
        }
    }
}

echo "Sleeping finished.\n";
```
```sh
php sleep.php 
Sleep 1: Complete
Sleep 2: Complete
Sleep 3: Complete
Sleep 4: Complete
Sleep 5: Complete
Sleeping finished.
```