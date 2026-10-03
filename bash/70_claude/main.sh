#!/usr/bin/env bash

command -v claude >/dev/null 2>&1 || { return; }

__rayrc_main() {
    __rayrc_module_common_setup

    if command -v aws >&/dev/null && \
       aws bedrock list-foundation-models --region ap-northeast-1 >&/dev/null; then
        export CLAUDE_CODE_USE_BEDROCK=1
        export AWS_REGION=ap-northeast-1
    fi

}

__rayrc_main
unset -f __rayrc_main
