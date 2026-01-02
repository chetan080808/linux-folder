#!/bin/bash

# Create user1
useradd -m -s /bin/bash user1
echo "user1:1234" | chpasswd

# Create user2
useradd -m -s /bin/bash user2
echo "user2:1234" | chpasswd

# Create user3
useradd -m -s /bin/bash user3
echo "user3:1234" | chpasswd

echo "All 3 users created successfully!"

