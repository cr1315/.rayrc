#!/usr/bin/env bash

parent() {
    local same_var

    same_var=parent

    echo "same_var in parent before calling child: $same_var"
    child
    echo "same_var in parent after calling child: $same_var"
}

child() {
    echo "same_var in child before local definition: $same_var"

    local same_var
    same_var=child

    echo "same_var in child after local definition: $same_var"
}

parent
