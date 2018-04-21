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
        if  echo `mount` | grep -q "$mountpoint"
        then
:
else
           echo "0" > $BUFFER/mount_check$mountpoint_to_filename
           exit
        fi

        ls $mountpoint 2> /dev/null > /dev/null

        if [ $? -eq 0 ]; then
            echo "1" > $BUFFER/mount_check$mountpoint_to_filename
        else
            echo "0" > $BUFFER/mount_check$mountpoint_to_filename
        fi
fi

