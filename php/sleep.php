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
