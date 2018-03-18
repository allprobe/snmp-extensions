#!/bin/bash

cli="$(ls "$1" | wc -l)"
echo $cli
