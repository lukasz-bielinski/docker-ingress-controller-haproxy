#!/bin/bash

STATE=$1
NOW=$(date +"%D %T")
LOGPATH="/"

case $STATE in
        "MASTER") touch $LOGPATH/keepalive.logs
                  echo "$NOW Becoming MASTER" >> $LOGPATH/keepalived.log
                  exit 0
                  ;;
        "BACKUP") rm $KEEPALIVED/MASTER
                  echo "$NOW Becoming BACKUP" >> $LOGPATH/keepalived.log
                  exit 0
                  ;;
        "FAULT")  rm $KEEPALIVED/MASTER
                  echo "$NOW Becoming FAULT" >> $LOGPATH/keepalived.log
                  echo ""
                  pkill -9 haproxy >> $LOGPATH/keepalived.log
                  exit 0
                  ;;
        *)        echo "unknown state"
                  echo "$NOW Becoming UNKOWN" >> $LOGPATH/keepalived.log
                  pkill -9 haproxy >> $LOGPATH/keepalived.log
                  exit 1
                  ;;
esac
