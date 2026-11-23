#!/usr/bin/env bash
######################################################################
#
# src/10_viewer/48_lfscp/lfscp のテスト
#   pack は lf を使わず、LFSCP_SESSION を一時フォルダに向けてパスを引数で渡す
#   起動モードは LFSCP_LF で偽の lf を渡し、端末は script で用意する
#   usage: bash test/lfscp/lfscp.sh
#
######################################################################

set -uo pipefail

__rayrc_test_main() {
    local root bin tmp sess log code tag i n
    local pass=0 fail=0

    root="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)"
    bin="${root}/src/10_viewer/48_lfscp/lfscp"
    tmp="$(mktemp -d)"
    ## 起動モードのセッションは /tmp/lfscp-* に作るので、テストごとの名前を付けて最後に消す
    tag="lfscptest$$"
    trap 'rm -rf -- "'"${tmp}"'" /tmp/lfscp-'"${tag}"'-*' RETURN

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
    __rayrc_t_session() { # <case> : 空のセッションを作り $sess に入れる
        sess="${tmp}/sess_$1"
        mkdir -p "${sess}/out" "${sess}/meta/work"
    }
    __rayrc_t_pack() { # <case> <args...> : 新しいセッションで pack して $code と $log を残す
        local c="$1"
        shift
        __rayrc_t_session "$c"
        __rayrc_t_pack_again "$@"
    }
    __rayrc_t_pack_again() { # <args...> : 今のセッションで pack を続けて実行する
        log="${sess}/log"
        LFSCP_SESSION="$sess" "$bin" pack "$@" >"$log" 2>&1
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
    __rayrc_t_count() { # <dir> : 中のファイル数（. で始まるものも数える）
        local n=0 f
        for f in "$1"/* "$1"/.[!.]* "$1"/..?*; do
            [[ -e "$f" ]] && n=$((n + 1))
        done
        echo "$n"
    }
    __rayrc_t_clean() { # meta/work に何も残っていない
        [[ $(__rayrc_t_count "${sess}/meta/work") -eq 0 ]]
    }
    __rayrc_t_fakebin() { # <dir> <除くコマンド> : 除くもの以外のコマンドだけを並べた PATH 用フォルダ
        local c p
        mkdir -p "$1"
        for c in bash env readlink dirname basename cat rm mv awk wc mkdir find id date cp cmp ln \
            git tar gzip bzip2 xz zip unzip python3; do
            [[ "$c" == "$2" ]] && continue
            p="$(type -P "$c")" && ln -s "$p" "$1/$c"
        done
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

    ## ---------- pack の共通部分 ----------
    log="${tmp}/log_nosession"
    LFSCP_SESSION= "$bin" pack git-bundle "${tmp}/r1" >"$log" 2>&1
    code=$?
    __rayrc_t_check "LFSCP_SESSION が無い → 1" \
        eval '[[ $code -eq 1 ]] && grep -q "LFSCP_SESSION" "$log"'

    __rayrc_t_pack unknown no-such-format "${tmp}/r1"
    __rayrc_t_check "知らない形式 → 1" \
        eval '[[ $code -eq 1 ]] && grep -q "知らない形式" "$log"'

    __rayrc_t_pack traversal ../lfscp "${tmp}/r1"
    __rayrc_t_check "形式名にパスを入れる → 1" \
        eval '[[ $code -eq 1 ]] && grep -q "知らない形式" "$log"'

    __rayrc_t_session nogit
    __rayrc_t_fakebin "${tmp}/bin_nogit" git
    log="${sess}/log"
    PATH="${tmp}/bin_nogit" LFSCP_SESSION="$sess" "${tmp}/bin_nogit/bash" "$bin" pack git-bundle "${tmp}/r1" >"$log" 2>&1
    code=$?
    __rayrc_t_check "必要なコマンドが無い（git）→ 1、名前を表示、out/ は無傷" \
        eval '[[ $code -eq 1 && $(__rayrc_t_count "$sess/out") -eq 0 ]] && grep -q "必要なコマンドがない：git" "$log"'

    ## ---------- git-bundle ----------
    __rayrc_t_pack one git-bundle "${tmp}/r1"
    __rayrc_t_check "git-bundle：1 件、verify が通る、meta/work は空、manifest に記録" \
        eval '[[ $code -eq 0 && $(__rayrc_t_count "$sess/out") -eq 1 && -f "$sess/out/r1.bundle" ]] && __rayrc_t_clean && git bundle list-heads "$sess/out/r1.bundle" >/dev/null && grep -q "^r1.bundle	git-bundle	${tmp}/r1\$" "$sess/meta/manifest.tsv"'

    __rayrc_t_pack samerepo git-bundle "${tmp}/r1/a.txt" "${tmp}/r1/sub/b.txt" "${tmp}/r1/sub"
    __rayrc_t_check "git-bundle：同じリポジトリのファイル・フォルダ → 1 件" \
        eval '[[ $code -eq 0 && $(__rayrc_t_count "$sess/out") -eq 1 && -f "$sess/out/r1.bundle" ]]'

    __rayrc_t_pack two git-bundle "${tmp}/r1" "${tmp}/r2"
    __rayrc_t_check "git-bundle：別々のリポジトリ 2 つ → 2 件" \
        eval '[[ $code -eq 0 && -f "$sess/out/r1.bundle" && -f "$sess/out/r2.bundle" ]]'

    __rayrc_t_pack norepo git-bundle "${tmp}/plain" "${tmp}/plain/x.txt"
    __rayrc_t_check "git-bundle：リポジトリでないものだけ → 何も作らず理由を出して 1" \
        eval '[[ $code -eq 1 && $(__rayrc_t_count "$sess/out") -eq 0 && $(grep -c "飛ばします：.*（リポジトリではない）" "$log") -eq 2 ]]'

    __rayrc_t_pack mixed git-bundle "${tmp}/r1" "${tmp}/plain" "${tmp}/nonexistent"
    __rayrc_t_check "git-bundle：混在 → リポジトリ分だけ作り、1" \
        eval '[[ $code -eq 1 && $(__rayrc_t_count "$sess/out") -eq 1 && $(grep -c "飛ばします" "$log") -eq 2 ]]'

    __rayrc_t_pack emptyrepo git-bundle "${tmp}/empty" "${tmp}/r2"
    __rayrc_t_check "git-bundle：コミットの無いリポジトリは失敗して飛ばし、ほかは作る。work は空" \
        eval '[[ $code -eq 1 && $(__rayrc_t_count "$sess/out") -eq 1 && -f "$sess/out/r2.bundle" ]] && __rayrc_t_clean && grep -q "作成に失敗したので飛ばします" "$log"'

    __rayrc_t_pack dirty git-bundle "${tmp}/dirty"
    __rayrc_t_check "git-bundle：未コミットの変更 → 件数と先頭 5 件を表示し、作る" \
        eval '[[ $code -eq 0 && -f "$sess/out/dirty.bundle" ]] && grep -q "未コミットの変更：8 件（バンドルには含まれない）" "$log" && [[ $(grep -c "^    [ MA?][ MA?] " "$log") -eq 5 ]]'

    __rayrc_t_pack worktree git-bundle "${tmp}/wt"
    __rayrc_t_check "git-bundle：worktree（.git がファイル）→ リポジトリとして扱う" \
        eval '[[ -f "${tmp}/wt/.git" && $code -eq 0 && -f "$sess/out/wt.bundle" ]] && grep -q "ブランチ：wtbranch" "$log"'

    ## ---------- 名前 ----------
    __rayrc_t_pack samename git-bundle "${tmp}/p1/same" "${tmp}/p2/same"
    __rayrc_t_check "名前：別の元で同じ base → 2 つ目は <親>_<名前>" \
        eval '[[ $code -eq 0 && -f "$sess/out/same.bundle" && -f "$sess/out/p2_same.bundle" ]]'
    __rayrc_t_pack_again git-bundle "${tmp}/p1/same" "${tmp}/p2/same"
    __rayrc_t_check "名前：同じ元を押し直す → 置き換えて件数は変わらない" \
        eval '[[ $code -eq 0 && $(__rayrc_t_count "$sess/out") -eq 2 && -f "$sess/out/same.bundle" && -f "$sess/out/p2_same.bundle" ]] && [[ $(grep -c "（置き換え）" "$log") -eq 2 && $(wc -l <"$sess/meta/manifest.tsv") -eq 2 ]]'
    __rayrc_t_repo "${tmp}/p3/same"
    __rayrc_t_pack_again git-bundle "${tmp}/p3/same"
    __rayrc_t_check "名前：<親>_ も重なる → _2" \
        eval '[[ $code -eq 0 && -f "$sess/out/p3_same.bundle" ]]'
    mkdir -p "${tmp}/p4"
    __rayrc_t_repo "${tmp}/p4/p2/same"
    __rayrc_t_pack_again git-bundle "${tmp}/p4/p2/same"
    __rayrc_t_check "名前：<親>_<名前> が別の元で使用中 → <親>_<名前>_2" \
        eval '[[ $code -eq 0 && -f "$sess/out/p2_same_2.bundle" && $(__rayrc_t_count "$sess/out") -eq 4 ]]'

    ## かごで消した名前を別の元が使った後、元の方を押し直しても新しい方を消さない
    __rayrc_t_pack reuse git-bundle "${tmp}/p1/same"
    rm -f -- "${sess}/out/same.bundle"
    __rayrc_t_pack_again git-bundle "${tmp}/p2/same"
    __rayrc_t_pack_again git-bundle "${tmp}/p1/same"
    __rayrc_t_check "名前：かごで消した名前を別の元が使う → 押し直しても他方を消さない" \
        eval '[[ $code -eq 0 && $(__rayrc_t_count "$sess/out") -eq 2 && -f "$sess/out/same.bundle" && -f "$sess/out/p1_same.bundle" ]] && grep -q "^same.bundle	git-bundle	${tmp}/p2/same\$" "$sess/meta/manifest.tsv"'

    __rayrc_t_pack dotname git-bundle "${tmp}/.q1/.dotrepo" "${tmp}/.q2/dotrepo"
    __rayrc_t_check "名前：先頭の . を外す（親も）" \
        eval '[[ $code -eq 0 && -f "$sess/out/dotrepo.bundle" && -f "$sess/out/q2_dotrepo.bundle" && $(__rayrc_t_count "$sess/out") -eq 2 ]]'

    ## ---------- 起動モード ----------
    ## 偽の lf：受け取った引数と環境を書き出し、FAKE_LF_PACK があればそれをかごに入れる
    cat >"${tmp}/fake-lf" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" >"${FAKE_LF_LOG}.args"
printf 'PATH=%s\nXDG_CONFIG_HOME=%s\nLFSCP_SESSION=%s\nLFSCP_SELF=%s\nTCELL=%s\n' \
    "$PATH" "$XDG_CONFIG_HOME" "$LFSCP_SESSION" "$LFSCP_SELF" "$TCELL_KEYBOARD_PROTOCOL" >"${FAKE_LF_LOG}.env"
if [[ -n "${FAKE_LF_PACK:-}" ]]; then
    "$LFSCP_SELF" pack git-bundle "$FAKE_LF_PACK"
fi
exit "${FAKE_LF_EXIT:-0}"
EOF
    chmod +x "${tmp}/fake-lf"
    __rayrc_t_launch() { # <case> <lfscp の引数...> : 端末付きで起動モードを実行する
        local c="$1" cmd q
        shift
        log="${tmp}/log_launch_$c"
        export FAKE_LF_LOG="${tmp}/fakelf_$c"
        cmd="LFSCP_LF='${tmp}/fake-lf'"
        for q in "$bin" "$@"; do
            cmd+=" '${q}'"
        done
        script -qec "$cmd" /dev/null >"$log" 2>&1 </dev/null
        code=$?
    }

    mkdir -p "/tmp/lfscp-${tag}-old" "/tmp/lfscp-${tag}-new"
    touch -d '2 days ago' "/tmp/lfscp-${tag}-old"
    __rayrc_t_launch empty -o "/tmp/lfscp-${tag}-empty" -s "${tmp}/r1"
    __rayrc_t_check "起動モード：何も作らずに抜ける → 2" \
        eval '[[ $code -eq 2 && -d "/tmp/lfscp-${tag}-empty/out" ]] && grep -q "かごが空" "$log"'
    __rayrc_t_check "起動モード：24 時間より古い自分のセッションは GC で消え、新しいものは残る" \
        eval '[[ ! -e "/tmp/lfscp-${tag}-old" && -d "/tmp/lfscp-${tag}-new" ]]'
    __rayrc_t_check "起動モード：セッションは 700、out と meta/work がある" \
        eval '[[ $(stat -c %a "/tmp/lfscp-${tag}-empty") == 700 && -d "/tmp/lfscp-${tag}-empty/meta/work" ]]'
    log="${FAKE_LF_LOG}.args"
    __rayrc_t_check "起動モード：lf に session.lfrc・go・開始フォルダを渡す" \
        eval 'diff <(printf "%s\n" -command "source '"'"'${root}/src/10_viewer/48_lfscp/session.lfrc'"'"'" -command "map go cd '"'"'/tmp/lfscp-${tag}-empty/out'"'"'" "${tmp}/r1") "$log" >/dev/null'
    log="${FAKE_LF_LOG}.env"
    __rayrc_t_check "起動モード：PATH の先頭に libs/bin、XDG・LFSCP_* を渡す" \
        eval 'grep -qx "PATH=${root}/libs/bin:.*" "$log" && grep -qx "XDG_CONFIG_HOME=${root}/libs/viewer/lf/config" "$log" && grep -qx "LFSCP_SESSION=/tmp/lfscp-${tag}-empty" "$log" && grep -qx "LFSCP_SELF=${bin}" "$log" && grep -qx "TCELL=legacy" "$log"'

    export FAKE_LF_PACK="${tmp}/r2"
    __rayrc_t_launch packed -o "/tmp/lfscp-${tag}-packed" -s "${tmp}/r1"
    unset FAKE_LF_PACK
    __rayrc_t_check "起動モード：lf の中で作る → 0、out/ に入っている" \
        eval '[[ $code -eq 0 && -f "/tmp/lfscp-${tag}-packed/out/r2.bundle" ]]'

    __rayrc_t_launch exists -o "/tmp/lfscp-${tag}-new" -s "${tmp}/r1"
    __rayrc_t_check "起動モード：セッションのフォルダが既にある → 1（-p を使っていない）" \
        eval '[[ $code -eq 1 && ! -e "${FAKE_LF_LOG}.args" ]] && grep -q "セッションフォルダを作れない" "$log"'

    n=0
    for i in "/tmp/lfscp-" "/tmp/lfscp-${tag}-x/y" "/tmp/lfscp-${tag}-a b" "/var/tmp/lfscp-${tag}-v" "/tmp/x/../lfscp-${tag}-dd" "tmp/lfscp-${tag}-rel"; do
        n=$((n + 1))
        __rayrc_t_launch "badpath${n}" -o "$i" -s "${tmp}/r1"
        __rayrc_t_check "起動モード：パターン外のパスを拒否（${i}）" \
            eval '[[ $code -eq 1 && ! -e "${FAKE_LF_LOG}.args" ]] && grep -q "/tmp/lfscp-<英数字" "$log"'
    done

    export FAKE_LF_EXIT=3
    __rayrc_t_launch lffail -o "/tmp/lfscp-${tag}-lffail" -s "${tmp}/r1"
    unset FAKE_LF_EXIT
    __rayrc_t_check "起動モード：lf が異常終了 → 1" \
        eval '[[ $code -eq 1 ]] && grep -q "lf が異常終了" "$log"'

    log="${tmp}/log_notty"
    LFSCP_LF="${tmp}/fake-lf" "$bin" -o "/tmp/lfscp-${tag}-notty" -s "${tmp}/r1" </dev/null >"$log" 2>&1
    code=$?
    __rayrc_t_check "起動モード：端末なし → 1、セッションを作らない" \
        eval '[[ $code -eq 1 && ! -e "/tmp/lfscp-${tag}-notty" ]] && grep -q "端末がない" "$log"'

    ## ---------- その他 ----------
    log="${tmp}/log_help"
    "$bin" help >"$log" 2>&1
    code=$?
    __rayrc_t_check "help → キーの一覧" \
        eval '[[ $code -eq 0 ]] && grep -q "^  tb  git-bundle" "$log"'

    log="${tmp}/log_mode"
    git -C "$root" ls-files -s src/10_viewer/48_lfscp/lfscp >"$log" 2>&1
    __rayrc_t_check "実行ビット：48_lfscp/lfscp が 100755（無いと Windows 側は 126）" \
        eval 'grep -q "^100755 " "$log"'

    echo ""
    echo "pass: ${pass}, fail: ${fail}"
    unset -f __rayrc_t_repo __rayrc_t_session __rayrc_t_pack __rayrc_t_pack_again __rayrc_t_check \
        __rayrc_t_count __rayrc_t_clean __rayrc_t_fakebin __rayrc_t_launch
    ((fail == 0))
}

__rayrc_test_main
__rayrc_test_rc=$?
unset -f __rayrc_test_main
exit "${__rayrc_test_rc}"
