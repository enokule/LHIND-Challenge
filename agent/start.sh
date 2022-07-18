#!/bin/sh

service docker stop
nohup docker daemon -H tcp://0.0.0.0:2375 -H unix:///var/run/docker.soc &
