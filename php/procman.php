<?php

register_shutdown_function("ProcessManager::flushThreads");

class ProcessManager {

    /** @var ProcessThread[][]  */
    static $processThreads = array();

    const STATUS_RUNNING  = "running";
    const STATUS_COMPLETE = "complete";
    const STATUS_ERROR    = "error";

    const POOL_EXTRACT = "extract";
    const POOL_LOAD    = "load";

    static function addThread($command, $name, $pool) {
        if (!isset(self::$processThreads[$pool])) {
            self::$processThreads[$pool] = array();
        }
        self::$processThreads[$pool][$name] = new ProcessThread($command);
    }

    /**
     * @param $pool
     * @param $name
     * @return ProcessThread
     * @throws \Exception
     */
    static function getThread($pool, $name) {
        if (isset(self::$processThreads[$pool][$name])) {
            return self::$processThreads[$pool][$name];
        }
        throw new \Exception("Unable to find process thread (name: $name, pool: $pool).");
    }

    static function getStatuses($pool) {
        $statuses = array();
        foreach (self::$processThreads[$pool] as $name => $thread) {
            /** @var $thread ProcessThread */
            $thread->update();
            if (!$thread->done) {
                $statuses[$name] = self::STATUS_RUNNING;
            }
            else if ($thread->error) {
                $statuses[$name] = self::STATUS_ERROR;
            }
            else {
                $statuses[$name] = self::STATUS_COMPLETE;
            }
        }
        return $statuses;
    }

    static function flushThreads($poolName=false) {
        foreach (self::$processThreads as $pool => $threads) {
            if ($poolName == $pool || $poolName == false) {
                foreach ($threads as $thread) {
                    /** @var $thread ProcessThread */
                    $thread->kill();
                }
                self::$processThreads[$pool] = array();
            }
        }
    }

    static function singleProcess($command) {
        $thread = new ProcessThread($command);
        while (!$thread->done) {
            sleep(0.05);
        }
        $thread->getError();
        $thread->close();
        return $thread;
    }

}

class ProcessThread {

    private $process = 0;
    private $pipes = array();
    private $timeout = 0;
    private $start_time;

    public $output = "";
    public $error = "";

    public $done = false;
    public $exit_code;

    public function __construct($command) {

        $descriptor = array (
            0 => array("pipe", "r"),
            1 => array("pipe", "w"),
            2 => array("pipe", "w")
        );

        $this->start_time = time();
        $this->process    = proc_open($command, $descriptor, $this->pipes);

        stream_set_blocking($this->pipes[1], 0);
        stream_set_blocking($this->pipes[2], 0);
    }

    public function update() {
        if ($this->done) {
            return;
        }
        $this->listen();
        $this->getError();
        $metaData = stream_get_meta_data($this->pipes[1]);
        if ($metaData["eof"]) {
            $this->close();
        }
    }

    public function listen() {
        if ($this->done) {
            return "";
        }
        $buffer = "";
        while ($line = fgets($this->pipes[1], 1024)) {
            $buffer .= $line;
        }
        $this->output .= $buffer;
        return $buffer;
    }

    public function getError() {
        if ($this->done) {
            return "";
        }
        $buffer = "";
        while ($line = fgets($this->pipes[2], 1024)) {
            $buffer .= $line;
        }
        $this->error .= $buffer;
        return $buffer;
    }

    public function close() {
        if (!$this->done) {
            $this->exit_code = proc_close($this->process);
            $this->process   = NULL;
            $this->done      = true;
        }
        return $this->exit_code;
    }

    public function kill() {
        if (!$this->done) {
            proc_terminate($this->process);
            $this->process = NULL;
            $this->done    = true;
        }
    }

    public function write($message) {
        fwrite($this->pipes[0], $message);
    }

    public function getStatus() {
        return proc_get_status($this->process);
    }

    public function isBusy() {
        return ($this->start_time > 0) && ($this->start_time + $this->timeout < time());
    }

}

class CLI {

    static private $rows = 0;
    static private $cols = 0;

    static public function doOutput($text) {
        if (self::$cols == 0) {
            self::$cols = exec("tput cols");
        }
        $line = preg_replace("/\r|\n/", "", trim($text));
        self::$rows += intval((strlen($line) - 1) / self::$cols) + 1;
        $lines[] = $line;
        echo $line . "\n";
        flush();
    }

    static public function reset() {
        self::$rows = 0;
    }

    static public function cursorBack() {
        echo "\033[0G";
        if (self::$rows > 0) {
            echo "\033[" . self::$rows . "A";
        }
        echo "\033[0J";
        self::reset();
    }

    static public function systemBell() {
        echo "\x07";
    }

}
