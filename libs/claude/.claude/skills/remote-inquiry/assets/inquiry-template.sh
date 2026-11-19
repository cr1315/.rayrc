#!/usr/bin/env bash
# <目的>の確認用。読み取りだけ。
#
# 使い方:
#   bash <名前>.sh                 # 結果は ./<日時>_<名前>.txt（日時が先頭。名前の順が時刻の順になる。区切りはすべて _）
#   OUT=xxx.txt bash <名前>.sh     # 結果のファイル名を指定する（PowerShell の断片から渡す）
#   ENVS="stg" bash <名前>.sh      # 対象を絞る
#   SKIP_KEYS=1 bash <名前>.sh     # 値に近い章（シークレットのキー名など）を飛ばす
#   SKIP_LOGS=1 bash <名前>.sh     # ログの章を飛ばす
#
# 出さないもの: シークレットの値、環境変数の値（SHOW_VALUES にあるものを除く）。
# ログの行は、メールアドレスを <email> に置き換え、長さを切って出す。
set -u   # set -e は使わない（1 つの失敗で全体を止めず、エラーは結果に残す）

OUT="${OUT:-./$(date +%Y%m%d_%H%M%S)_<名前>.txt}"
ENVS="${ENVS:-dev stg}"
SHOW_VALUES='SPRING_PROFILES_ACTIVE'    # 値を出してよいものだけを並べる

# --- 実行場所の検査（どちらか、または両方） ---
EXPECTED_ACCOUNT="${EXPECTED_ACCOUNT:-<AWS のアカウント ID>}"
EXPECTED_HOST_PATTERN="${EXPECTED_HOST_PATTERN:-}"   # 例: 'bastion'

h1() { printf '\n\n######## %s\n' "$*"; }
h2() { printf '\n==== %s\n' "$*"; }

# 標準入力の行から、メールアドレスを伏せ、1 行を $1 文字に切る
mask() {
  W="${1:-300}" python3 -I -c '
import os, re, sys
w = int(os.environ["W"])
email = re.compile(r"[\w.+-]+@[\w-]+(\.[\w-]+)+")
for line in sys.stdin:
    print(email.sub("<email>", line.rstrip("\n"))[:w])
'
}

main() {
  h1 "0. 実行環境"
  date '+%F %T %z'
  hostname
  if [ -n "$EXPECTED_HOST_PATTERN" ] && ! hostname | grep -q -- "$EXPECTED_HOST_PATTERN"; then
    echo "!! ホスト名が $EXPECTED_HOST_PATTERN に合わないので中止する"
    return 1
  fi
  if command -v aws >/dev/null 2>&1; then
    account=$(aws sts get-caller-identity --query Account --output text 2>&1)
    echo "Account: $account"
    if [ "$account" != "$EXPECTED_ACCOUNT" ]; then
      echo "!! アカウントが $EXPECTED_ACCOUNT ではないので中止する"
      return 1
    fi
  fi

  for e in $ENVS; do
    h1 "1. [$e] <見るもの>"
    # 例: aws ecs describe-services ... --query '{...}' 2>&1
    # 値を含む JSON は python3 -I で必要な項目だけ取り出し、SHOW_VALUES 以外の値は伏せる
  done

  h1 "2. <値に近いもの>"
  if [ "${SKIP_KEYS:-}" = "1" ]; then
    echo "(SKIP_KEYS=1 のため飛ばした)"
  else
    :  # 例: シークレットは ARN 全体で問い合わせ、JSON のキー名だけを出す
  fi

  h1 "3. <ログ>"
  if [ "${SKIP_LOGS:-}" = "1" ]; then
    echo "(SKIP_LOGS=1 のため飛ばした)"
  else
    :  # 例: ... | mask 300 | tail -5
  fi

  h1 "おわり"
}

main 2>&1 | tee "$OUT"
echo
echo "結果: $OUT"
