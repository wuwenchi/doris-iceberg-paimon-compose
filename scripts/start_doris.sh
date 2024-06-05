#!/usr/bin/env bash

export PATH=$JAVA_HOME/bin:$PATH

echo 'start to copy...'
cp -r /opt/doris-bin /opt/doris

echo 'start fe...'
rm -rf /opt/doris/fe/doris-meta/*
/opt/doris/fe/bin/start_fe.sh --daemon

echo 'start be...'
rm -rf /opt/doris/be/storage/*
/opt/doris/be/bin/start_be.sh --daemon

echo 'doris is started'

tail -F /dev/null