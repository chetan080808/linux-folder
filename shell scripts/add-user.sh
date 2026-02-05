#!/bin/bash

for user in dev1 dev2 dev3
do
    if id $user >/dev/null 2>&1; then
        echo "User $user already exists"
    else
        useradd $user
        echo "User $user created"
    fi
done
