#!/usr/bin/env bash
######################################################################
#
# bash/10_viewer/20_git/rayrc-git-bundle のテスト
#   lf を使わず、パスを引数で渡して確認する
#   usage: bash test/git_bundle/git_bundle.sh
#
######################################################################

set -uo pipefail

__rayrc_test_main() {
    local root bin tmp out log code
    local pass=0 fail=0

    root="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)"
    bin="${root}/bash/10_viewer/20_git/rayrc-git-bundle"
    tmp="$(mktemp -d)"
    trap 'rm -rf -- "'"${tmp}"'"' RETURN

    export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.com
    export GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.com

    ## ---------- helpers ----------
    __rayrc_t_repo() { # <path> : コミット 1 つのリポジトリを作る
        mkdir -p "$1/sub"
        git -C "$1" init -q -b main
        echo a >"$1/a.txt"
        echo b >"$1/sub/b.txt"
        git -C "$1" add -A
        git -C "$1" commit -q -m init
    }
    __rayrc_t_run() { # <case> <args...> : 実行して $code と $log を残す
        out="${tmp}/out_$1"
        log="${tmp}/log_$1"
        shift
        "$bin" -o "$out" "$@" >"$log" 2>&1
        code=$?
    }
    __rayrc_t_check() { # <name> <cond...>
        local name="$1"
        shift
        if "$@"; then
            echo "ok   ${name}"
            pass=$((pass + 1))
        else
            echo "FAIL ${name}"
            sed 's/^/       | /' "$log"
            fail=$((fail + 1))
        fi
    }
    __rayrc_t_count() { # <dir> : *.bundle の数
        local n=0 f
        for f in "$1"/*.bundle; do
            [[ -e "$f" ]] && n=$((n + 1))
        done
        echo "$n"
    }

    ## ---------- fixtures ----------
    __rayrc_t_repo "${tmp}/r1"
    __rayrc_t_repo "${tmp}/r2"
    __rayrc_t_repo "${tmp}/p1/same"
    __rayrc_t_repo "${tmp}/p2/same"
    __rayrc_t_repo "${tmp}/.q1/.dotrepo"
    __rayrc_t_repo "${tmp}/.q2/dotrepo"
    mkdir -p "${tmp}/plain"
    echo x >"${tmp}/plain/x.txt"
    mkdir -p "${tmp}/empty"
    git -C "${tmp}/empty" init -q -b main
    __rayrc_t_repo "${tmp}/dirty"
    for i in 1 2 3 4 5 6 7; do echo "$i" >"${tmp}/dirty/new${i}.txt"; done
    echo changed >>"${tmp}/dirty/a.txt"
    git -C "${tmp}/r1" worktree add -q "${tmp}/wt" -b wtbranch

    ## ---------- cases ----------
    __rayrc_t_run one "${tmp}/r1"
    __rayrc_t_check "リポジトリ 1 つ → バンドル 1 つ、verify OK、0" \
        eval '[[ $code -eq 0 && $(__rayrc_t_count "$out") -eq 1 && -f "$out/r1.bundle" ]] && grep -q "verify OK" "$log" && git bundle list-heads "$out/r1.bundle" >/dev/null'

    __rayrc_t_run samerepo "${tmp}/r1/a.txt" "${tmp}/r1/sub/b.txt"
    __rayrc_t_check "同じリポジトリのファイル 2 つ → バンドル 1 つ" \
        eval '[[ $code -eq 0 && $(__rayrc_t_count "$out") -eq 1 && -f "$out/r1.bundle" ]]'

    __rayrc_t_run two "${tmp}/r1" "${tmp}/r2"
    __rayrc_t_check "別々のリポジトリ 2 つ → バンドル 2 つ" \
        eval '[[ $code -eq 0 && $(__rayrc_t_count "$out") -eq 2 && -f "$out/r1.bundle" && -f "$out/r2.bundle" ]]'

    __rayrc_t_run norepo "${tmp}/plain" "${tmp}/plain/x.txt"
    __rayrc_t_check "リポジトリでないものだけ → 何も作らず 3" \
        eval '[[ $code -eq 3 && ! -e "$out" ]] && grep -q "無視" "$log"'

    __rayrc_t_run mixed "${tmp}/r1" "${tmp}/plain" "${tmp}/nonexistent"
    __rayrc_t_check "リポジトリと非リポジトリの混在 → リポジトリ分だけ、無視を表示、0" \
        eval '[[ $code -eq 0 && $(__rayrc_t_count "$out") -eq 1 && $(grep -c "無視" "$log") -eq 2 ]]'

    __rayrc_t_run samename "${tmp}/p1/same" "${tmp}/p2/same"
    __rayrc_t_check "同じフォルダ名 2 つ → 2 つ目は <親>_<名前>.bundle" \
        eval '[[ $code -eq 0 && -f "$out/same.bundle" && -f "$out/p2_same.bundle" ]]'

    __rayrc_t_run dotname "${tmp}/.q1/.dotrepo" "${tmp}/.q2/dotrepo"
    __rayrc_t_check ". で始まるフォルダ名 → 先頭の . を外す（*.bundle で拾える）" \
        eval '[[ $code -eq 0 && -f "$out/dotrepo.bundle" && -f "$out/q2_dotrepo.bundle" && $(__rayrc_t_count "$out") -eq 2 ]] && ! ls -A "$out" | grep -q "^\."'

    __rayrc_t_run emptyonly "${tmp}/empty"
    __rayrc_t_check "コミットのないリポジトリだけ → 飛ばして 3" \
        eval '[[ $code -eq 3 && $(__rayrc_t_count "$out") -eq 0 ]] && grep -q "失敗したので飛ばします" "$log"'

    __rayrc_t_run emptymix "${tmp}/empty" "${tmp}/r2"
    __rayrc_t_check "コミットのないリポジトリ + 普通のリポジトリ → 普通の分だけ、0" \
        eval '[[ $code -eq 0 && $(__rayrc_t_count "$out") -eq 1 && -f "$out/r2.bundle" ]]'

    __rayrc_t_run dirty "${tmp}/dirty"
    __rayrc_t_check "未コミットの変更 → 件数と先頭 5 件を表示し、バンドルは作る" \
        eval '[[ $code -eq 0 && -f "$out/dirty.bundle" ]] && grep -q "未コミットの変更：8 件（バンドルには含まれない）" "$log" && [[ $(grep -c "^    [ MA?][ MA?] " "$log") -eq 5 ]]'

    __rayrc_t_run worktree "${tmp}/wt"
    __rayrc_t_check "worktree（.git がファイル）→ リポジトリとして扱う" \
        eval '[[ -f "${tmp}/wt/.git" && $code -eq 0 && -f "$out/wt.bundle" ]] && grep -q "ブランチ：wtbranch" "$log"'

    __rayrc_t_run subdir "${tmp}/r2/sub"
    __rayrc_t_check "サブフォルダ → 最上位のリポジトリのバンドル" \
        eval '[[ $code -eq 0 && $(__rayrc_t_count "$out") -eq 1 && -f "$out/r2.bundle" ]]'

    ## -o 省略: /tmp/scp-git-<ユーザー名>-<日時>-<乱数> に作られ、scp の例が出る
    log="${tmp}/log_noout"
    "$bin" "${tmp}/r1" >"$log" 2>&1
    code=$?
    out="$(sed -n 's/^出力フォルダ：//p' "$log")"
    __rayrc_t_check "-o 省略 → /tmp/scp-git-<ユーザー名>-<日時>-<乱数>、scp の例を表示" \
        eval '[[ $code -eq 0 && "$out" =~ ^/tmp/scp-git-${USER:-$(id -un)}-[0-9]{8}-[0-9]{6}-[0-9]{4}$ && -f "$out/r1.bundle" && $(stat -c %a "$out") == 700 ]] && grep -q "scp.exe <host>:${out}/\*.bundle \." "$log"'
    [[ "$out" == /tmp/scp-git-* ]] && rm -rf -- "$out"

    ## 引数なし + 端末なし → lf を開けず 1
    log="${tmp}/log_notty"
    (cd "${tmp}/r1" && "$bin" -o "${tmp}/out_notty" </dev/null >"$log" 2>&1)
    code=$?
    __rayrc_t_check "端末なしで lf を起動しようとした → 1" \
        eval '[[ $code -eq 1 ]] && grep -q "端末がない" "$log"'

    echo ""
    echo "pass: ${pass}, fail: ${fail}"
    unset -f __rayrc_t_repo __rayrc_t_run __rayrc_t_check __rayrc_t_count
    ((fail == 0))
}

__rayrc_test_main
__rayrc_test_rc=$?
unset -f __rayrc_test_main
exit "${__rayrc_test_rc}"
