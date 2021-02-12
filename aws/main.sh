### aws_completer
complete -C `which aws_completer` aws



### for aws authentication
aws.mfa() {
    unset AWS_PROFILE
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset AWS_SESSION_TOKEN
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
    serial_number="$(aws iam list-mfa-devices | jq -r '.MFADevices[0].SerialNumber')"
    credential=$(aws sts get-session-token --duration-seconds $duration --serial-number $serial_number --token-code $auth_code)
    export AWS_ACCESS_KEY_ID=$(echo $credential | jq -r '.Credentials.AccessKeyId')
    export AWS_SECRET_ACCESS_KEY=$(echo $credential | jq -r '.Credentials.SecretAccessKey')
    export AWS_SESSION_TOKEN=$(echo $credential | jq -r '.Credentials.SessionToken')
    unset auth_code
    unset serial_number
    unset duration
    unset credential
}

aws.iac() {
    unset AWS_PROFILE
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset AWS_SESSION_TOKEN
    if [[ $# -gt 0 && $1 =~ [0-9]{6} ]]; then
        auth_code=$1
    else
        read -p "code please: " auth_code
    fi
    aws.mfa $auth_code 900

    # now we can many things, the first thing we're going to do is sarani elevate our priviledge
    # aws secretsmanager get-secret-value --secret-id dev/kddi-cdx/cdx-terraform/cicd | jq ".SecretString|fromjson" | jq 'with_entries(select(.key | test("Key")))' | jq 'with_entries(.key |= (gsub("(?<=.)(?<var>[A-Z])"; "_"+.var)|ascii_upcase))' | jq -r 'to_entries[] | "export \(.key)=\(.value)"'
    iacCredential=$(aws secretsmanager get-secret-value --secret-id dev/kddi-cdx/cdx-terraform/cicd | jq ".SecretString|fromjson")
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset AWS_SESSION_TOKEN
    export AWS_ACCESS_KEY_ID=$(echo $iacCredential | jq -r '.AwsAccessKeyId')
    export AWS_SECRET_ACCESS_KEY=$(echo $iacCredential | jq -r '.AwsSecretAccessKey')

    unset auth_code
    unset iacCredential
}