#!/usr/bin/env bash

showpath() {
    ## BSD sed (macOS) does not turn `\n` in the replacement into a newline; use zsh's $path array
    print -rl -- $path
}
