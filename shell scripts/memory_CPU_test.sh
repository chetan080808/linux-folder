#!/bin/bash

# Install stress-ng if not already installed
sudo apt update && sudo apt install stress -y

# Run memory stress test (uses 1GB RAM for 2 minutes)
echo "Starting memory stress test..."
echo "This will use 1GB RAM for 2 minutes"
stress --cpu 2 --io 2 --vm 2 --vm-bytes 512M --timeout 120s

echo "Test completed! Check CloudWatch for memory spike"
