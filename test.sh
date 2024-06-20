#!/bin/bash
shutdown_runner() {
echo "Caught $1 - Shutting down runner"
exit
}

trap shutdown_runner SIGINT SIGQUIT SIGTERM INT TERM QUIT

# Example long-running task
echo "Running... (press Ctrl+C to trigger SIGINT)"
while true; do
  sleep 1
done
