#!/bin/bash

cli="$(ps -aux  | grep "$1" | grep -v grep | "grep" -v "/bin/bash" | wc -l)"
echo $cli
