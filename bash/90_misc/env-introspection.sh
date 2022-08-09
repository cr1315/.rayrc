#!/usr/bin/env bash
#######################################################################
# Name:
# Author:
# Date:
# Description:
#
#
#
#
#
#
#######################################################################

declare -A ENV_CLOUDFRONT_NAMES
ENV_CLOUDFRONT_NAMES=(
    ["us1"]="self.onst.poda1-1.dxq.au.com|self-bg.onst.poda1-1.dxq.au.com"
    ["prd"]="self.onst.poda1-1.dx.au.com|self-bg.onst.poda1-1.dx.au.com"
)

declare -A ALB_PATTERNS
ALB_PATTERNS=()

main() {
    local cfDomainNames
    # echo \"$env\"
    cfDomainNames=(${ENV_CLOUDFRONT_NAMES[${env}]//|/ })
    # echo \"${cfDomainNames[@]}\"
    for cfDomainName in "${cfDomainNames[@]}"; do

        cfName=$(jq -r --arg cfDomainName "^$cfDomainName" '.ResourceRecordSets[] | select(.Name | test($cfDomainName)) | .AliasTarget.DNSName' RESOURCE_RECORD_SETS.json)
        # echo \"$cfName\"

        cloudfront=$(jq --arg cfName "$cfName?$" '.DistributionList.Items[] | select(.DomainName | test($cfName))' CLOUDFRONT_DISTRIBUTIONS.json)
        originDomainName=$(jq -r '.Origins.Items[] | select(.Id| test("apigw-custom-domain")) | .DomainName' <<<"${cloudfront}")
        # echo $originDomainName

        apigwDomainName=$(jq -r --arg originDomainName "^$originDomainName" '.ResourceRecordSets[] | select(.Name | test($originDomainName)) | .AliasTarget.DNSName' RESOURCE_RECORD_SETS.json)
        # echo $apigwDomainName

        restApiIds=$(aws apigateway get-base-path-mappings --domain-name "${originDomainName#.}" | jq -r '.items[].restApiId')
        # echo $restApiIds

        for restApiId in ${restApiIds}; do
            echo "${restApiId}"
            resourceMethods=$(aws apigateway get-resources --rest-api-id "${restApiId}" | jq -r '.items[] | select(.resourceMethods?) | "\(.id)|\((.resourceMethods|keys)[0])"')

            declare -a resultArray
            resultArray=()
            for resourceMethod in $resourceMethods; do
                resourceMethodArray=(${resourceMethod//|/ })
                resourceId=${resourceMethodArray[0]}
                httpMethod=${resourceMethodArray[1]}
                # echo \"$resourceId\" \"$httpMethod\"

                resultArray+=" $(aws apigateway get-method --rest-api-id $restApiId --resource-id $resourceId --http-method $httpMethod | jq -r '.methodIntegration.uri | gsub("^https?://(?<domain>[^/]+)/.*$"; .domain)')"
            done

            albDomainName=$(echo $(echo "${resultArray[@]}" | tr " " "\n" | uniq))
            albHostName=$(jq -r --arg albDomainName "^$albDomainName" '.ResourceRecordSets[] | select(.Name | test($albDomainName)) | .AliasTarget.DNSName' RESOURCE_RECORD_SETS.json)
            # echo \"$albHostName\"

            albArn=$(jq -r --arg albHostName "^${albHostName#dualstack.}?$" '.LoadBalancers[] | select(.DNSName | test($albHostName)) | .LoadBalancerArn' LOAD_BALANCERS.json)
            # echo \"$albArn\"

            # jq --arg albHostName "^${albHostName#dualstack.}?$" '.LoadBalancers[] | select(.DNSName | test($albHostName))' LOAD_BALANCERS.json

            targetGroupArn=$(aws elbv2 describe-target-groups --load-balancer-arn $albArn | jq -r '.TargetGroups[0].TargetGroupArn')
            # echo \"$targetGroupArn\"

            targetHealthInfo=$(aws elbv2 describe-target-health --target-group-arn $targetGroupArn)
            instanceId=$(jq -r '.TargetHealthDescriptions[0].Target.Id')
            nodePort=$(jq -r '.TargetHealthDescriptions[0].Target.Port')

            #clusterId=$(aws ec2 describe-instance-attribute --instance-id "i-026f5a8053c027273" --attribute userData | jq -r '.UserData.Value|@base64d' | grep -P "/etc/eks/bootstrap.sh" | sed -E -e 's|^\s*/etc/eks/bootstrap.sh\s+"?||' -e 's|"\s+$||')

            echo \"$clusterId\"

            kubectl get svc -A -o json | jq '.items[] | select(.spec.ports[0]?.nodePort?) | "\(.metadata.namespace) \(.spec.ports[0].nodePort)"'

            exit
            # for .. in .. ; do
            # aws apigateway get-method
        done
    done
}

#######################################################################
# PARAMETER CHECK
#######################################################################
checkParameter() {
    true
}

#######################################################################
# AWS COMMON FUNCTION
#######################################################################
getCfArnFromRR() {
    true
}

getAlbDomainNames() {

    cfName=$(aws route53 list-resource-record-sets --hosted-zone-id Z02099911YFURCCGUFMSV |
        jq -r --arg cfDomainName "^apigw\c*\.onst" '.ResourceRecordSets[] | select(.Name | test($cfDomainName)) | .AliasTarget.DNSName' RESOURCE_RECORD_SETS.json)

    true
}

getRRWithPattern() {
    aws route53 list-resource-record-sets --hosted-zone-id Z02099911YFURCCGUFMSV | jq -r --arg cfDomainName "alb-bg.onst" '
        .ResourceRecordSets[] | select(.Name | test($cfDomainName)) | .AliasTarget.DNSName
    '
}

#######################################################################
# LOG
#######################################################################
info() {
    true
}

debug() {
    true
}

#######################################################################
# TEST
#######################################################################
prepareEnvTest() {
    env="us1"

    [[ ! -f RESOURCE_RECORD_SETS.json ]] && RESOURCE_RECORD_SETS=$(aws route53 list-resource-record-sets --hosted-zone-id Z02099911YFURCCGUFMSV)
    [[ ! -f CLOUDFRONT_DISTRIBUTIONS.json ]] && CLOUDFRONT_DISTRIBUTIONS=$(aws cloudfront list-distributions)
    [[ ! -f TARGET_GROUPS.json ]] && TARGET_GROUPS=$(aws elbv2 describe-target-groups)
    [[ ! -f LOAD_BALANCERS.json ]] && LOAD_BALANCERS=$(aws elbv2 describe-load-balancers)
}

getCloudfrontArnFromDomainNameTest() {
    true
}

#######################################################################
# GO
#######################################################################
prepareEnvTest
main "$@"
exit
