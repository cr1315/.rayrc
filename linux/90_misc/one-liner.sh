

## cognito userpool custom-domains
(for id in $(aws cognito-idp list-user-pools --max-results 60 | jq -r '.UserPools[].Id'); do aws cognito-idp describe-user-pool --user-pool-id "$id" | jq -r '"\(.UserPool.Name) \(.UserPool.Domain) \(.UserPool.CustomDomain)"'; done) | awk '{printf "%-40s\t%-44s\t%s\n",$1,$2,$3}' | sort


## autoscaling group schedule
### list autoscaling group scheduled status
aws autoscaling describe-scheduled-actions | TZ="Asia/Tokyo" LC_TIME="ja_JP.UTF-8" jq -r '.ScheduledUpdateGroupActions[] | select( .ScheduledActionName|test("02-11-stop$") ) | "\(.AutoScalingGroupName) \(.ScheduledActionName) \(.StartTime | strptime("%Y-%m-%dT%H:%M:%S%z") | mktime | localtime | strftime("%FT%T%Z"))"' | awk '{printf "%-30s\t%-55s\t%s\n",$1,$2,$3}' | sort

### batch put-scheduled-update-group-action
aws autoscaling describe-scheduled-actions | TZ="Asia/Tokyo" LC_TIME="ja_JP.UTF-8" jq -r '.ScheduledUpdateGroupActions[] | select( .ScheduledActionName|test("02-11-stop$") ) | "\(.AutoScalingGroupName) \(.ScheduledActionName) \(.StartTime | strptime("%Y-%m-%dT%H:%M:%S%z") | mktime | localtime | strftime("%FT%T%Z"))"' | TZ=UTC awk -v newStart=$(date +"%s" -d '2021-05-26 21:00:00+0900') '{cmdline = sprintf("aws autoscaling put-scheduled-update-group-action --auto-scaling-group-name %s --scheduled-action-name %s --desired-capacity 0 --start-time %s",$1,$2,strftime("%FT%TZ", newStart)); print cmdline}' | sort

### localtime to utc time
jq -n '"2021-05-25 21:00:00" | (strptime("%Y-%m-%d %H:%M:%S") | mktime - 32400) | strftime("%FT%TZ")'
TZ=UTC awk -v JST2UTC=$(date +"%s" -d '2021-05-25 21:00:00+0900') 'BEGIN{ print strftime("%FT%TZ", JST2UTC), JST2UTC }'

## create web acl
### create rules.json
### fix bugs after this command
jq '.[].Statement.AndStatement.Statements[0].ByteMatchStatement.SearchString |= @base64' cloudfront02.json

### create
aws wafv2 create-web-acl --name "cdx-a-g-k-webacl-cloudfront02" --scope CLOUDFRONT --region us-east-1 --default-action "Block={}" --visibility-config "SampledRequestsEnabled=true,CloudWatchMetricsEnabled=true,MetricName=cdx-a-g-k-webacl-cloudfront02" --rules file://cloudfront02.json









