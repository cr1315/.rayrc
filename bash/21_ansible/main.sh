#!/usr/bin/env bash

# aliases
if command -v ansible >/dev/null 2>&1; then
    true
else
    alias ansible="poetry run ansible"
    alias ansible-playbook="poetry run ansible-playbook"
fi
