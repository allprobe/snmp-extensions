#!/bin/bash

BUFFER="/etc/apr/buffer"

if [[ ! -e $BUFFER ]]; then
            mkdir $BUFFER
fi

wget -O /etc/apr/buffer/apache_status http://127.0.0.1/apache-status-apr?auto
