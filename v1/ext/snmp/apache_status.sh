#!/bin/bash

apache_variable=$1
apache_status=$(cat /etc/apr/buffer/apache_status)


if [[ -z $apache_variable ]]; then
    echo "Unsupported variable!"
    exit 1
fi
 
if [[ -z $apache_status ]]; then
    echo "apache status is empty!"
    exit 1
fi


case $1 in
'TotalAccesses')
    echo "$apache_status"|grep "Total Accesses:"|awk '{print $3}'
    value=$?;;
'TotalKBytes')
    echo "$apache_status"|grep "Total kBytes:"|awk '{print $3}'
    value=$?;;
'Uptime')
    echo "$apache_status"|grep "Uptime:"|awk '{print $2}'
    value=$?;;
'ReqPerSec')
    echo "$apache_status"|grep "ReqPerSec:"|awk '{print $2}'
    value=$?;;
'BytesPerSec')
    echo "$apache_status"|grep "BytesPerSec:"|awk '{print $2}'
    value=$?;;
'BytesPerReq')
    echo "$apache_status"|grep "BytesPerReq:"|awk '{print $2}'
    value=$?;;
'BusyWorkers')
    echo "$apache_status"|grep "BusyWorkers:"|awk '{print $2}'
    value=$?;;
'IdleWorkers')
    echo "$apache_status"|grep "IdleWorkers:"|awk '{print $2}'
    value=$?;;
'WaitingForConnection')
    echo "$apache_status"|grep "Scoreboard:"| awk '{print $2}'| awk 'BEGIN { FS = "_" } ; { print NF-1 }'
    value=$?;;
'StartingUp')
    echo "$apache_status"|grep "Scoreboard:"| awk '{print $2}'| awk 'BEGIN { FS = "S" } ; { print NF-1 }'
    value=$?;;
'ReadingRequest')
    echo "$apache_status"|grep "Scoreboard:"| awk '{print $2}'| awk 'BEGIN { FS = "R" } ; { print NF-1 }'
    value=$?;;
'SendingReply')
    echo "$apache_status"|grep "Scoreboard:"| awk '{print $2}'| awk 'BEGIN { FS = "W" } ; { print NF-1 }'
    value=$?;;
'KeepAlive')
    echo "$apache_status"|grep "Scoreboard:"| awk '{print $2}'| awk 'BEGIN { FS = "K" } ; { print NF-1 }'
    value=$?;;
'DNSLookup')
    echo "$apache_status"|grep "Scoreboard:"| awk '{print $2}'| awk 'BEGIN { FS = "D" } ; { print NF-1 }'
    value=$?;;
'ClosingConnection')
    echo "$apache_status"|grep "Scoreboard:"| awk '{print $2}'| awk 'BEGIN { FS = "C" } ; { print NF-1 }'
    value=$?;;
'Logging')
    echo "$apache_status"|grep "Scoreboard:"| awk '{print $2}'| awk 'BEGIN { FS = "L" } ; { print NF-1 }'
    value=$?;;
'GracefullyFinishing')
    echo "$apache_status"|grep "Scoreboard:"| awk '{print $2}'| awk 'BEGIN { FS = "G" } ; { print NF-1 }'
    value=$?;;
'IdleCleanupOfWorker')
    echo "$apache_status"|grep "Scoreboard:"| awk '{print $2}'| awk 'BEGIN { FS = "I" } ; { print NF-1 }'
    value=$?;;
'OpenSlotWithNoCurrentProcess')
    echo "$apache_status"|grep "Scoreboard:"| awk '{print $2}'| awk 'BEGIN { FS = "." } ; { print NF-1 }'
    value=$?;;
*)
    echo "Unsupported variable! not in the list!"
    exit ;;
esac
 
if [ "$value" -ne 0 ]; then
      echo "Error while getting variable value!"
fi
 
exit $value