#!/usr/bin/env bash

showpath() {
    echo $PATH | sed -e 's/:/\n/g'
}

pubip() {
    curl http://checkip.amazonaws.com
}
