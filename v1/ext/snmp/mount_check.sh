#!/bin/bash

BUFFER="/etc/apr/buffer"
mountpoint="$1"
mountpoint_to_filename=`echo ${mountpoint//\//_}`

CMD=`cat $BUFFER/mount_check$mountpoint_to_filename`
OUTPUT=$CMD
echo $OUTPUT
