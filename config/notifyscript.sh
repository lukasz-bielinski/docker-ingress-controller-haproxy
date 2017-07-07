#!/bin/bash

STATE=$1
NOW=$(date +"%D %T")
LOGPATH="/"

case $STATE in
        "MASTER") touch $LOGPATH/keepalive.logs
                  echo "$NOW Becoming MASTER" >> $LOGPATH/keepalived.log
                  haproxy  -W -D -f /config/haproxy.cfg -p /var/run/haproxy.pid -sf $(cat /var/run/haproxy.pid) -x /var/run/haproxy.sock
                  exit 0
                  ;;
        "BACKUP") rm $KEEPALIVED/MASTER
                  echo "$NOW Becoming BACKUP" >> $LOGPATH/keepalived.log
                  exit 0
                  ;;
        "FAULT")  rm $KEEPALIVED/MASTER
                  echo "$NOW Becoming FAULT" >> $LOGPATH/keepalived.log
                  echo ""
                  exit 0
                  ;;
        *)        echo "unknown state"
                  echo "$NOW Becoming UNKOWN" >> $LOGPATH/keepalived.log
                  exit 1
                  ;;
esac
