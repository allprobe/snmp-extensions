#!/bin/bash

mysql_variable=$1
while read line; do
  if [[ $line == *"$mysql_variable"* ]]; then
    echo "$line" |awk  '{print $2}'
    exit 1
  fi
done </etc/apr/buffer/mysql_global_variables