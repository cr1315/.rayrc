#!/usr/bin/env bash
#
# ローカルの作業ツリーをクリーンなコンテナにコピーして install し、
# 対話シェルのランタイム状態（alias / 関数 / env / キーバインド）を取得する。
# push 不要（作業ツリーを ro マウントする）。
#
#   snapshot.sh <bash|zsh> <out-prefix>
#   snapshot.sh --normalize <out-prefix>   … 既存の .raw から .txt だけを作り直す
#
#   <out-prefix>.raw     … コンテナの stdout そのまま（install ログ + スナップショット）
#   <out-prefix>.stderr  … コンテナの stderr
#   <out-prefix>.txt     … 比較用。スナップショット部分のみを正規化したもの
#
# 正規化:
#   - .rayrc/{bash,zsh,powershell,src} → .rayrc/<CTL>
#   - env の PWD / SHLVL / _ / OLDPWD を除外
#   - 実行ごとに変わる値を <X> に置換する（キーは残して存在を比較する）。
#     同一コミットで 2 回取得した差分から特定したもの:
#       HOSTNAME（コンテナ ID）/ ATUIN_SESSION（乱数）/ fnm_multishells/<pid>_<ms>
#
# 前提: docker build -t rayrc-test -f .claude/skills/rayrc-docker-test/Dockerfile .
#

set -u

die() {
    echo "snapshot.sh: $*" >&2
    exit 1
}

marker='@@@RAYRC_SNAPSHOT@@@'

normalize() {
    local out="$1"
    grep -q "^${marker}\$" "${out}.raw" || die "snapshot marker not found; see ${out}.raw / ${out}.stderr"

    sed -n "/^${marker}\$/,\$p" "${out}.raw" | tail -n +2 \
        | sed -E \
            -e 's#\.rayrc/(bash|zsh|powershell|src)\b#.rayrc/<CTL>#g' \
            -e 's#^(HOSTNAME|ATUIN_SESSION)=.*#\1=<X>#' \
            -e 's#fnm_multishells/[0-9]+_[0-9]+#fnm_multishells/<X>#g' \
        | grep -vE '^(PWD|SHLVL|_|OLDPWD)=' >"${out}.txt"
}

if [[ $# -eq 2 && "$1" == "--normalize" ]]; then
    normalize "$2"
    exit 0
fi

[[ $# -eq 2 ]] || die "usage: snapshot.sh <bash|zsh> <out-prefix> | --normalize <out-prefix>"
shell="$1"
out="$2"
root="$(cd "$(dirname "$0")/.." && pwd -P)"

case "${shell}" in
    bash)
        read -r -d '' script <<'EOF'
cp -a /work /root/.rayrc && cd /root && source .rayrc/install
echo "INSTALL_RC=$?"
echo "@@@RAYRC_SNAPSHOT@@@"
bash -ic "alias -p; declare -F; env | sort; echo PC=\$PROMPT_COMMAND"
EOF
        ;;
    zsh)
        ## ${(k)functions} はハッシュ順なので (o) で整列させる
        read -r -d '' script <<'EOF'
apt-get update -qq && apt-get install -y -qq zsh >/dev/null || exit 8
cp -a /work /root/.rayrc && cd /root && touch .zshrc && zsh -c "source .rayrc/install"
echo "INSTALL_RC=$?"
echo "@@@RAYRC_SNAPSHOT@@@"
zsh -ic "alias; print -l \${(ko)functions}; env | sort; bindkey"
EOF
        ;;
    *)
        die "unsupported shell: ${shell}"
        ;;
esac

docker run --rm -v "${root}":/work:ro rayrc-test bash -c "${script}" \
    >"${out}.raw" 2>"${out}.stderr"
rc=$?

normalize "${out}"

echo "snapshot.sh: ${shell}: docker rc=${rc}, $(grep '^INSTALL_RC=' "${out}.raw"), $(wc -l <"${out}.txt") lines -> ${out}.txt"
