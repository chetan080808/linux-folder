#!/bin/bash

service="nginx"

if systemctl is-active $service; then
    echo "$service is running"
else
    echo "$service is not running. Restarting..."
    systemctl restart $service
fi
