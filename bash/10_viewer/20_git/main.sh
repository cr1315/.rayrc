#!/usr/bin/env bash

command -v git >/dev/null 2>&1 || { return; }

__rayrc_main() {
    __rayrc_module_common_setup

    export GITSTATUS_CACHE_DIR="${__rayrc_bin_dir}"

    ## add GITSTATUS_DIR for .rayrc_per_series
    export GITSTATUS_DIR="${__rayrc_data_dir}/gitstatus/gitstatus.plugin.sh"

    if [[ -f "${GITSTATUS_DIR}" ]]; then
        # TODO: determine if we are in docker
        # TODO: move to docker main.sh?
        if [ -f /.dockerenv ]; then
            export __rayrc_inside_docker=$'\033[1m (docker)\033[00m'
        else
            export __rayrc_inside_docker=""
        fi

        source "${__rayrc_data_dir}/gitstatus.prompt.sh"
        source "${__rayrc_ctl_dir}/functions.sh"
    fi

    ## __rayrc_ctl_dir は読み込み中だけの一時変数なので、exported 関数 git-bundle-pick から
    ## 参照できるよう別名で export しておく
    export __RAYRC_GIT_CTL_DIR="${__rayrc_ctl_dir}"

    # only for places without network..
    # [[ ! -f "$HOME/.cache/gitstatus/gitstatusd-linux-x86_64" ]] && cp -fp "`which gitstatusd-linux-x86_64`" "$HOME/.cache/gitstatus/gitstatusd-linux-x86_64"

}

__rayrc_main
unset -f __rayrc_main

## lf で選んだリポジトリを git bundle にする（本体は rayrc-git-bundle。Windows の scp-git からは
## フルパスで直接呼ばれる）。gitstatus の有無に関係なく、git があれば使える。
## 子プロセス(bash -c, navi 等)からも呼べるよう export -f する
git-bundle-pick() {
    "${__RAYRC_GIT_CTL_DIR}/rayrc-git-bundle" "$@"
}
export -f git-bundle-pick
