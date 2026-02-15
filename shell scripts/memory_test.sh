#!/bin/bash

# Install stress-ng if not already installed
sudo apt-get update && sudo apt-get install stress-ng -y

# Run memory stress test (uses 1GB RAM for 2 minutes)
echo "Starting memory stress test..."
echo "This will use 1GB RAM for 2 minutes"
stress-ng --vm 2 --vm-bytes 512M --timeout 120s

echo "Test completed! Check CloudWatch for memory spike"
