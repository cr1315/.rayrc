# ecs.sh と同じ: クラスターのタスクを fzf で選んで ECS Exec で入る
function ecs.exec {
  param([Parameter(Mandatory = $true)][string]$ClusterName)
  $task = aws ecs list-tasks --cluster $ClusterName | jq -r '.taskArns[]' |
    fzf --preview 'echo {}' --preview-window down:40%:wrap
  if (-not $task) { return }
  aws ecs execute-command --interactive --cluster $ClusterName --command '/bin/bash' --task $task
}
