#!/usr/bin/env bash

showpath() {
    echo $PATH | sed -e 's/:/\n/g'
}

ip.pub() {
    curl http://checkip.amazonaws.com
}
