#!/usr/bin/env zsh
######################################################################
##
## ② 一括：zip とフォルダの配置、入れ子のたどり方、どのページに入れるか、タイトル
##   zip を扱うのはこの層だけ。ページの読み書きは ③ ページ（page.zsh）に任せる。
##   「何が正か」は __rayrc_cf_decide_title と __rayrc_cf_decide_target の 2 つに集める。
##   層の分け方と決まりは リファクタリング.md を参照。
##
## zip の配置
##   <ページ ID>_<タイトル>.zip       1 ページ 1 zip（中身は ③ のページのフォルダ）
##   <ページ ID>_<タイトル>/          子のページの zip を入れるフォルダ（-r。孫以下も同じ）
##   子の並び順は、親の page.json の children に書く（書いていない子は名前の順）
##
######################################################################

## __rayrc_cf_zip_id <zip> → REPLY=<zip の名前の先頭のページ ID>。なければ 1 を返す
__rayrc_cf_zip_id() {
    emulate -L zsh -o extended_glob
    [[ "${1:t}" == (#b)([0-9]##)_* ]] || return 1
    REPLY="${match[1]}"
}

## __rayrc_cf_decide_title <-t の値> <ページのフォルダ> <zip> <page|parent> → REPLY=<タイトル>
## 上から順に、最初に見つかったものを使う
##   1. -t
##   2. page.xhtml の最初の要素の <h1>
##   3. page.json の title
##   4. ページを指定したとき：空（今のタイトルのまま）
##      親の下に入れるとき  ：zip の名前（先頭の <数字>_ を除く）
__rayrc_cf_decide_title() {
    emulate -L zsh -o extended_glob
    local override="$1"
    local dir="$2"
    local zip="$3"
    local kind="$4"

    REPLY="${override}"
    [[ -n "${REPLY}" ]] && return 0

    if __rayrc_cf_page_heading "${dir}/page.xhtml"; then
        REPLY="${reply[1]}"
        return 0
    fi

    if [[ -f "${dir}/page.json" ]]; then
        REPLY="$(jq -r '.title // empty' "${dir}/page.json")" || return 8
        [[ -n "${REPLY}" ]] && return 0
    fi

    REPLY=''
    [[ "${kind}" == page ]] && return 0
    REPLY="${${zip:t:r}#[0-9]##_}"
}

## __rayrc_cf_decide_target <認証> <サイト> <page|parent> <ページ ID|親 ID> <ページのフォルダ> <タイトル>
##   → reply=(update <ページ ID>) か reply=(create <親 ID>)
## ページを指定したとき：そのページを更新する
## 親の下に入れるとき  ：上から順に
##   1. page.json の site が同じで、その id のページが親の直下にあれば、それを更新する（タイトルを変えても同じページ）
##   2. 親の直下に同じタイトルのページがあれば、それを更新する
##   3. どちらもなければ、親の下に作る
__rayrc_cf_decide_target() {
    emulate -L zsh
    local auth="$1"
    local site="$2"
    local kind="$3"
    local ref="$4"
    local dir="$5"
    local title="$6"

    if [[ "${kind}" == page ]]; then
        reply=(update "${ref}")
        return 0
    fi

    __rayrc_cf_children "${auth}" "${site}" "${ref}" || return 8
    local kids="${REPLY}"
    local hit=''
    if [[ -f "${dir}/page.json" ]]; then
        hit="$(jq -r --arg site "${site}" --argjson kids "${kids}" '
            select((.site // "" | ascii_downcase) == $site) | .id as $id
            | first($kids[] | select(.id == $id) | .id) // empty' "${dir}/page.json")" || return 8
    fi
    if [[ -z "${hit}" ]]; then
        hit="$(jq -r --arg t "${title}" 'first(.[] | select(.title == $t) | .id) // empty' <<<"${kids}")" || return 8
    fi
    if [[ -n "${hit}" ]]; then
        reply=(update "${hit}")
    else
        reply=(create "${ref}")
    fi
}

## __rayrc_cf_bulk_import <認証> <サイト> <zip> <page|parent> <ページ ID|親 ID> <-t の値> <版のメッセージ> <prune> <recursive>
## zip を 1 つ取り込む。recursive が true なら、zip と同じ名前のフォルダの中の zip を、このページの子として取り込む
## → REPLY=<ページ ID>
__rayrc_cf_bulk_import() {
    emulate -L zsh -o extended_glob
    local auth="$1"
    local site="$2"
    local zip="$3"
    local kind="$4"
    local ref="$5"
    local override="$6"
    local message="$7"
    local prune="$8"
    local recursive="$9"
    local id
    local -a order

    local work
    work="$(mktemp -d "${TMPDIR:-/tmp}/confluence-import_XXXXXXXX")" || return 8
    {
        print -r -- "zip：${zip}"
        unzip -q "${zip}" -d "${work}" || return 8
        local -a found
        found=("${work}"/**/page.xhtml(N.))
        if (( ${#found} != 1 )); then
            __rayrc_cf_err "zip の中に page.xhtml がちょうど 1 つ必要です（見つかった数：${#found}）：${zip}"
            return 8
        fi
        local dir="${found[1]:h}"

        __rayrc_cf_decide_title "${override}" "${dir}" "${zip}" "${kind}" || return 8
        local title="${REPLY}"
        __rayrc_cf_decide_target "${auth}" "${site}" "${kind}" "${ref}" "${dir}" "${title}" || return 8
        __rayrc_cf_page_push "${auth}" "${site}" "${dir}" "${reply[1]}" "${reply[2]}" \
            "${title}" "${message}" "${prune}" || return 8
        id="${REPLY}"

        if [[ "${recursive}" == true && -f "${dir}/page.json" ]]; then
            order=(${(f)"$(jq -r '.children[]?.id' "${dir}/page.json")"})
        fi
    } always {
        rm -rf -- "${work}"
    }

    # 子（zip と同じ名前のフォルダの中の zip）。page.json の children の順、書いていないものは名前の順
    if [[ "${recursive}" == true && -d "${zip:r}" ]]; then
        local -a zips sorted
        local k z
        zips=("${zip:r}"/*.zip(N.))
        for k in "${order[@]}"; do
            for z in "${zips[@]}"; do
                [[ "${z:t}" == "${k}"_* ]] && sorted+=("${z}")
            done
        done
        for z in "${zips[@]}"; do
            (( ${sorted[(Ie)$z]} )) || sorted+=("${z}")
        done
        for z in "${sorted[@]}"; do
            __rayrc_cf_bulk_import "${auth}" "${site}" "${z}" parent "${id}" '' "${message}" "${prune}" true || return 8
        done
    fi
    REPLY="${id}"
}

## __rayrc_cf_bulk_export <認証> <サイト> <ページ ID> <出力フォルダ> <force> <recursive>
## ページを <ページ ID>_<タイトル>.zip に書き出す。recursive が true なら、子を zip と同じ名前のフォルダに書き出す
__rayrc_cf_bulk_export() {
    emulate -L zsh -o extended_glob
    local auth="$1"
    local site="$2"
    local id="$3"
    local outdir="$4"
    local force="$5"
    local recursive="$6"

    __rayrc_cf_page_info "${auth}" "${site}" "${id}" || return 8
    local info="${REPLY}"
    local title version
    title="$(jq -r '.title' <<<"${info}")" || return 8
    version="$(jq -r '.version.number' <<<"${info}")" || return 8

    local unsafe='[\\/:*?"<>|[:space:]]##'
    local safe="${title//${~unsafe}/_}"
    safe="${${safe##_##}%%_##}"
    safe="${safe[1,60]}"
    local out="${outdir}/${id}_${safe}.zip"
    if [[ -e "${out}" && "${force}" != true ]]; then
        __rayrc_cf_err "すでにあります（上書きするときは -f）：${out}"
        return 8
    fi
    print -r -- "ページ：${title}（版 ${version}、ID ${id}）"

    local kids='[]'
    if [[ "${recursive}" == true ]]; then
        __rayrc_cf_children "${auth}" "${site}" "${id}" || return 8
        kids="${REPLY}"
    fi

    local work
    work="$(mktemp -d "${TMPDIR:-/tmp}/confluence-export_XXXXXXXX")" || return 8
    {
        __rayrc_cf_page_pull "${auth}" "${site}" "${info}" "${work}" || return 8
        local natt="${REPLY}"
        if [[ "${recursive}" == true ]]; then
            jq --argjson kids "${kids}" '. + {children: [$kids[] | {id, title}]}' \
                "${work}/page.json" >"${work}/.page.json" || return 8
            mv -- "${work}/.page.json" "${work}/page.json" || return 8
        fi

        [[ -e "${out}" ]] && { rm -f -- "${out}" || return 8; }
        ( cd -- "${work}" && zip -qrX "${out}" . ) || return 8
        print -r -- "完了（版 ${version}、添付 ${natt} 件）：${out}"
    } always {
        rm -rf -- "${work}"
    }

    # 子（zip と同じ名前のフォルダに書き出す）
    if [[ "${recursive}" == true ]] && (( $(jq 'length' <<<"${kids}") )); then
        local kid
        mkdir -p -- "${out:r}" || return 8
        for kid in ${(f)"$(jq -r '.[].id' <<<"${kids}")"}; do
            __rayrc_cf_bulk_export "${auth}" "${site}" "${kid}" "${out:r}" "${force}" true || return 8
        done
    fi
}
