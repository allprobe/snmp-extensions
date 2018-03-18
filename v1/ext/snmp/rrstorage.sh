#!/bin/bash

/bin/touch /data/rankranger/domains/rankranger.com/www/stor/buffer/test 2> /dev/null && { /bin/rm /data/rankranger/domains/rankranger.com/www/stor/buffer/test 2> /dev/null ; echo 1; } || echo 0
