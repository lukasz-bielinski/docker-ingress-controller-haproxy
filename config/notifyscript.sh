#!/bin/bash

STATE=$1
NOW=$(date +"%D %T")
LOGPATH="/"

case $STATE in
        "MASTER") touch $LOGPATH/keepalive.logs
                  echo "$NOW Becoming MASTER" >> $LOGPATH/keepalive.logs
                  exit 0
                  ;;
        "BACKUP") rm $KEEPALIVED/MASTER
                  echo "$NOW Becoming BACKUP" >> $LOGPATH/keepalive.logs
                  exit 0
                  ;;
        "FAULT")  rm $KEEPALIVED/MASTER
                  echo "$NOW Becoming FAULT" >> $LOGPATH/keepalive.logs
                  echo ""
                  echo "$NOW Trying to launch haproxy..." >> $LOGPATH/keepalive.logs
                  pkill -9 haproxy;    haproxy  -W -D -f /config/haproxy.cfg -p /var/run/haproxy.pid -sf $(cat /var/run/haproxy.pid) -x /var/run/haproxy.sock >> $LOGPATH/keepalive.logs
                  exit 0
                  ;;
        *)        echo "unknown state"
                  echo "$NOW Becoming UNKOWN" >> $LOGPATH/keepalive.logs
                  exit 1
                  ;;
esac
