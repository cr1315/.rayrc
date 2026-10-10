#!/usr/bin/env bash

showpath() {
    echo $PATH | sed -e 's/:/\n/g'
}
