#!/usr/bin/env zsh

command -v aws >/dev/null 2>&1 || { return; }

__rayrc_main() {
    __rayrc_module_common_setup

    ### aws_completer: a bash `complete -C` completer, run through bashcompinit
    ### (needs compinit, which rayrc does not run itself)
    if (( ${+functions[compdef]} )) && command -v aws_completer >/dev/null 2>&1; then
        autoload -U +X bashcompinit && bashcompinit
        complete -C "$(command -v aws_completer)" aws
    fi

    export AWS_REGION=ap-northeast-1

    source "${__rayrc_ctl_dir}/ecs.zsh"
}

__rayrc_main
unset -f __rayrc_main
