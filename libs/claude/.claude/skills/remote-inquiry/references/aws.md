# 調べる先が AWS のときの注意

スポーク B の AWS CLI で、別のアカウントを読むときに、実際につまずいたこと。

## 実行場所の検査

- 最初に `aws sts get-caller-identity --query Account --output text` で、アカウント ID が想定どおりかを確かめ、違えば止める。
- 想定のアカウント ID は、会話・記録・手元のファイル（タスク定義の ARN など）から取る。分からなければ確認のカードで聞く。

## 「動いているもの」を見る

- ECS では、サービスが使っているタスク定義（`describe-services` の `taskDefinition` と `deployments[].taskDefinition`）を見る。ファミリーの最新の版が、動いているものとは限らない。
- 止まったタスクの理由（`list-tasks --desired-status STOPPED` → `describe-tasks` の `stoppedReason`）も一緒に取ると、起動の失敗を切り分けやすい。
- 手元のタスク定義との突き合わせは、`environment` と `secrets` を名前で並べ替えてから比べる（順番の違いで差分が出ないように）。

## Secrets Manager

- ARN の末尾（`-AbCdEf` の 6 文字）付きの名前で `--secret-id` に渡すと、「見つからない」（`ResourceNotFoundException`）になる。**ARN 全体**か、末尾なしの名前で問い合わせる。
- 中身は、`get-secret-value` で取ったうえで、**JSON のキー名だけ**を出す（値は出さない）。タスク定義の `valueFrom` の `:<キー>::` と突き合わせると、参照の誤りが分かる。
- 証明書などの、JSON でないシークレットは読まない。

## CloudWatch Logs

- `filter-log-events` は期間（`--start-time`）に注意する。起動のログはデプロイの時刻にしか出ないので、期間が短いと「0 件」になる。起動を見たいときは、デプロイの日時を含む期間にする。
- フィルターのパターンは、語ごとに `"..."` で囲む（例：`"Started" "seconds"`）。どれか 1 つに当たればよいときは `?語1 ?語2`。
- 出すのは件数と最後の数行だけにし、メールアドレスを伏せ、長さを切る。

## IAM

- 実行ロールなどの権限は、`list-attached-role-policies` → `get-policy` → `get-policy-version`、インラインは `list-role-policies` → `get-role-policy` で、ポリシーの文書まで取る。リソースの範囲（`<prefix>-*` など）で、読めるシークレットが決まっていることが多い。

## SES

- `sesv2 get-account` で、サンドボックスかどうか（`ProductionAccessEnabled`）が分かる。サンドボックスでは、送信元だけでなく宛先も検証済みでないと送れない。
- `sesv2 list-email-identities` には、個人のメールアドレスが並ぶことがある。結果のファイルは共有しない。記録には、ドメインと件数くらいにとどめる。
