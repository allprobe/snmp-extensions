#!/bin/bash

BUFFER="/etc/apr/buffer"

case $1 in
    user)
        CMD=`cat $BUFFER/vmstat | awk '{print $13}'`
        ;;
    system)
        CMD=`cat $BUFFER/vmstat | awk '{print $14}'`
        ;;
    idle)
        CMD=`cat $BUFFER/vmstat | awk '{print $15}'`
        ;;
    watime)
        CMD=`cat $BUFFER/vmstat | awk '{print $16}'`
        ;;
    cs)
        CMD=`cat $BUFFER/vmstat | awk '{print $12}'`
        ;;
    interrupts)
        CMD=`cat $BUFFER/vmstat | awk '{print $11}'`
        ;;
    si)
        CMD=`cat $BUFFER/vmstat | awk '{print $7}'`
        ;;
    so)
        CMD=`cat $BUFFER/vmstat | awk '{print $8}'`
        ;;
    bi)
        CMD=`cat $BUFFER/vmstat | awk '{print $9}'`
        ;;
    bo)
        CMD=`cat $BUFFER/vmstat | awk '{print $10}'`
        ;;
    running)
        CMD=`cat $BUFFER/vmstat | awk '{print $1}'`
        ;;
    blocked)
        CMD=`cat $BUFFER/vmstat | awk '{print $2}'`
        ;;
    *)
        echo "Unknown argument"
esac

OUTPUT=$CMD

if [ $? -eq 0 ]; then
    echo $OUTPUT
else
    echo "0"
fi

