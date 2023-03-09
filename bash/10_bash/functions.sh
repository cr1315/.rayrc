#!/usr/bin/env bash

showpath() {
    echo $PATH | sed -e 's/:/\n/g'
}

ip.public() {
    curl http://checkip.amazonaws.com
}


aws.publicip() {
    curl http://checkip.amazonaws.com
}

