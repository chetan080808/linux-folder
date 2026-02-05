#!/bin/bash

tmp_dir="/tmp"

for file in $tmp_dir/*
do
    rm -rf $file
done

echo "Temporary files cleaned"
