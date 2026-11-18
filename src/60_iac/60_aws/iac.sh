#!/usr/bin/env bash

aws.iac() {
    if [[ "$(aws.env)" == "dev" ]]; then
        aws.iac_dev
    elif [[ "$(aws.env)" == "stg" ]]; then
        aws.iac_stg
    else
        echo "unsupported environment.."
    fi
}

aws.iac_dev() {
    local devCredential
    local secretId
    local rc

    # test mfa
    aws secretsmanager list-secrets >&/dev/null
    if [[ $? != 0 ]]; then
        local auth_code
        if [[ $# -gt 0 && $1 =~ [0-9]{6} ]]; then
            auth_code=$1
        else
            read -p "need to mfa yourself first, code please: " auth_code
        fi
        aws.mfa $auth_code 900
        rc=$?
        if [[ $rc != 0 ]]; then
            echo "mfa failed.."
            return $rc
        fi
    fi

    secretId=$(aws secretsmanager list-secrets | jq -r '.SecretList[].Name' | grep terraform)
    devCredential=$(aws secretsmanager get-secret-value --secret-id $secretId | jq ".SecretString|fromjson")
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset AWS_SESSION_TOKEN
    export AWS_ACCESS_KEY_ID=$(echo "$devCredential" | jq -r '.AwsAccessKeyId')
    export AWS_SECRET_ACCESS_KEY=$(echo "$devCredential" | jq -r '.AwsSecretAccessKey')
}

aws.iac_stg() {
    local stgCredential
    local secretId
    local rc

    # test mfa
    aws secretsmanager list-secrets >&/dev/null
    if [[ $? != 0 ]]; then
        aws.stg
        rc=$?
        if [[ $rc != 0 ]]; then
            echo "assume-role to stg-admin failed.."
            return $rc
        fi
    fi

    secretId=$(aws secretsmanager list-secrets | jq -r '.SecretList[].Name' | grep terraform)
    stgCredential=$(aws secretsmanager get-secret-value --secret-id $secretId | jq ".SecretString|fromjson")
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset AWS_SESSION_TOKEN
    export AWS_ACCESS_KEY_ID=$(echo "$stgCredential" | jq -r '.AwsAccessKeyId')
    export AWS_SECRET_ACCESS_KEY=$(echo "$stgCredential" | jq -r '.AwsSecretAccessKey')
}
