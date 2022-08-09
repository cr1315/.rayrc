#!/usr/bin/env bash

command -v utladmin >/dev/null 2>&1 || { return; }

hulft() {
    export TERM=xterm
    command utladmin
    export TERM=xterm-256color
}

utladmin() {
    export TERM=xterm
    command utladmin
    export TERM=xterm-256color
}
