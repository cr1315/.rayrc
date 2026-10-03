#!/usr/bin/env bash

aws.env() {
    local accountId
    accountId=

    if command -v curl >&/dev/null; then
        accountId=$(curl -s "http://169.254.169.254/latest/dynamic/instance-identity/document" | jq -r '.accountId')
    elif command -v wget >&/dev/null; then
        accountId=$(wget -qO- "http://169.254.169.254/latest/dynamic/instance-identity/document" | jq -r '.accountId')
    else
        echo "couldnot detect the env.."
    fi

    if [[ "$accountId" == "$ACCOUNT_ID_DEV"* ]]; then
        echo "dev"
    elif [[ "$accountId" == "$ACCOUNT_ID_STG"* ]]; then
        echo "stg"
    else
        true
    fi
}

### for aws authentication
aws.mfa() {
    trap 'local rc=$?; trap - ERR; return $rc' ERR
    local auth_code
    local duration

    # TODO: parameter check
    if [[ $# -gt 0 && $1 =~ [0-9]{6} ]]; then
        auth_code=$1
    else
        read -p "code please: " auth_code
    fi

    if [[ $2 =~ [0-9]+ ]]; then
        duration=$2
    else
        duration=43200
    fi

    local serial_number
    local credential
    serial_number="$(aws iam list-mfa-devices | jq -r '.MFADevices[0].SerialNumber')"
    credential=$(aws sts get-session-token --duration-seconds $duration --serial-number $serial_number --token-code $auth_code)

    unset AWS_PROFILE
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset AWS_SESSION_TOKEN
    export AWS_ACCESS_KEY_ID=$(echo "$credential" | jq -r '.Credentials.AccessKeyId')
    export AWS_SECRET_ACCESS_KEY=$(echo "$credential" | jq -r '.Credentials.SecretAccessKey')
    export AWS_SESSION_TOKEN=$(echo "$credential" | jq -r '.Credentials.SessionToken')

    trap - ERR
}

aws.stg() {
    local credential
    local target_role_arn
    local rc

    # test privilege
    aws iam list-roles >&/dev/null
    rc="$?"
    if [[ $rc != 0 ]]; then
        if [[ $# -gt 0 && $1 =~ [0-9]{6} ]]; then
            auth_code=$1
        else
            echo "please mfa yourself first,"
            read -p "code please: " auth_code
        fi

        aws.mfa $auth_code 900
        rc=$?
        if [[ $rc != 0 ]]; then
            return $rc
        fi
    fi

    # TODO: target_role_arn=$(aws iam list-roles | jq -r '.Roles[].Arn' | grep 'From')
    credential=$(aws sts assume-role --role-arn "arn:aws:iam::${ACCOUNT_ID_STG}:role/switchRole-From-dev" --role-session-name "stg-admin" --duration-seconds 3600 2>/dev/null)
    rc=$?
    if [[ $rc != 0 ]]; then
        echo "failed to \`assume-role'"
        return $rc
    fi

    # we got the credential
    unset AWS_PROFILE
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset AWS_SESSION_TOKEN
    export AWS_ACCESS_KEY_ID=$(echo "$credential" | jq -r '.Credentials.AccessKeyId')
    export AWS_SECRET_ACCESS_KEY=$(echo "$credential" | jq -r '.Credentials.SecretAccessKey')
    export AWS_SESSION_TOKEN=$(echo "$credential" | jq -r '.Credentials.SessionToken')
}


aws.assume() {
    local credential
    local target_role_arn
    local external_id
    local rc

    target_role_arn="$1"
    external_id="$2"

    # TODO: target_role_arn=$(aws iam list-roles | jq -r '.Roles[].Arn' | grep 'From')
    if [[ -z "$external_id" ]]; then
        credential=$(aws sts assume-role --role-arn $target_role_arn --role-session-name "assume_role" --duration-seconds 3600 2>&1)
    else
        credential=$(aws sts assume-role --role-arn $target_role_arn --external-id "$external_id" --role-session-name "assume_role" --duration-seconds 3600 2>&1)
    fi
    rc=$?
    if [[ $rc != 0 ]]; then
        echo "failed to \`assume-role'"
        echo "$credential"
        return $rc
    fi

    # we got the credential
    unset AWS_PROFILE
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset AWS_SESSION_TOKEN
    export AWS_ACCESS_KEY_ID=$(echo "$credential" | jq -r '.Credentials.AccessKeyId')
    export AWS_SECRET_ACCESS_KEY=$(echo "$credential" | jq -r '.Credentials.SecretAccessKey')
    export AWS_SESSION_TOKEN=$(echo "$credential" | jq -r '.Credentials.SessionToken')
}

aws.resume() {
    # we got the credential
    unset AWS_PROFILE
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset AWS_SESSION_TOKEN
}
