#!/usr/bin/env bash

command -v aws >/dev/null 2>&1 || { return; }

### aws_completer
complete -C $(which aws_completer) aws

aws.publicip() {
    curl http://checkip.amazonaws.com
}

aws.apigwips() {
    curl -sSL "https://ip-ranges.amazonaws.com/ip-ranges.json" | jq '[
        .prefixes[] |
        select(.service=="API_GATEWAY" and .region=="ap-northeast-1") |
        .ip_prefix
    ]'
}

aws.icips() {
    curl -sSL "https://ip-ranges.amazonaws.com/ip-ranges.json" | jq '[
        .prefixes[] |
        select(.service=="EC2_INSTANCE_CONNECT" and .region=="ap-northeast-1") |
        .ip_prefix
    ]'
}

__rayrc_main() {
    __rayrc_module_common_setup
    source "${__rayrc_ctl_dir}/mfa.sh"
}

__rayrc_main
unset -f __rayrc_main
