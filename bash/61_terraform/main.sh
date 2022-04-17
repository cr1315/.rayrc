#!/usr/bin/env bash

command -v terraform >/dev/null 2>&1 || { return; }


alias tf="terraform"