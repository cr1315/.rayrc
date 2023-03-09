#!/usr/bin/env bash

command -v aws >/dev/null 2>&1 || { return; }

### aws_completer
complete -C $(which aws_completer) aws

ec2.start_tester() {
    local instance_id
    instance_id=$(aws ec2 describe-instances --filters 'Name=tag:Name,Values=nszd_tester' --output text --query 'Reservations[*].Instances[*].InstanceId' | head -1)
    aws ec2 start-instances --instance-ids "${instance_id}"
}

__rayrc_main() {
    __rayrc_module_common_setup
    source "${__rayrc_ctl_dir}/mfa.sh"
}

__rayrc_main
unset -f __rayrc_main
