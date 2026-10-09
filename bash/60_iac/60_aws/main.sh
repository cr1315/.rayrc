#!/usr/bin/env bash

command -v aws >/dev/null 2>&1 || { return; }


__rayrc_main() {
    __rayrc_module_common_setup

    ### aws_completer
    complete -C $(which aws_completer) aws

    export AWS_REGION=ap-northeast-1

    source "${__rayrc_ctl_dir}/ecs.sh"
}

__rayrc_main
unset -f __rayrc_main
