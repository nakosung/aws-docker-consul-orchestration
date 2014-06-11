#!/bin/bash

#include common.sh
#include wait.sh

sudo sh -c "nohup consul agent -server -join='CONSUL_LEADER_IP' -data-dir=/tmp/consul > /var/log/consul.log 2>&1 &"