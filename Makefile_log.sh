#!/bin/sh

# This logging wrapper script forwards all parameters to a "make" call.

LOG_DIR=log
mkdir -p $LOG_DIR
NOW=$(date +"%F_%H-%M-%S")
LOG_FILE="$LOG_DIR/build_$NOW.log"

{
make $@
} 2>&1 | tee $LOG_FILE
