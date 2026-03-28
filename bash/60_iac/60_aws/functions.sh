#!/usr/bin/env bash

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
