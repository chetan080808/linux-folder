#!/bin/bash

log_dir="/var/log"
days=7

if [ -d $log_dir ]; then
    echo "Cleaning logs older than $days days in $log_dir"

    find $log_dir -type f -mtime +$days -exec rm -f {} \;

    echo "Log cleanup completed"
else
    echo "Log directory not found"
fi
