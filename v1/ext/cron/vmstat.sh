#!/bin/bash

BUFFER="/etc/apr/buffer"

if [[ ! -e $BUFFER ]]; then
            mkdir $BUFFER
fi

CMD=`/usr/bin/vmstat 1 2 | awk '{if (NR == 4) {print $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16}}'`
echo $CMD > $BUFFER/vmstat
