


get-eventlog -logname System -source Microsoft-Windows-GroupPolicy -new 10 | sort instanceid | ft -wrap -auto

