#!/bin/bash

BUFFER="/etc/apr/buffer"

if [[ ! -e $BUFFER ]]; then
            mkdir $BUFFER
fi

mountpoint="$1"
mountpoint_to_filename=`echo ${mountpoint//\//_}`

read -t1 < <(stat -t "$mountpoint" 2>&-)
if [ -z "$REPLY" ] ; then
        echo "0" > $BUFFER/mount_check$mountpoint_to_filename
else
        echo "1" > $BUFFER/mount_check$mountpoint_to_filename
fi



