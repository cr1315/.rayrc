#!/usr/bin/env bash

command -v git >/dev/null 2>&1 || { return; }

# set a global git config only when it is unset; keep (and warn about) a value changed by hand
__rayrc_git_config_ensure() {
    local key="$1"
    local want="$2"
    local current

    if ! current="$(git config --global --get "${key}")"; then
        git config --global "${key}" "${want}"
    elif [[ "${current}" != "${want}" ]]; then
        __rayrc_log_warn "git config ${key} is '${current}' (rayrc default: '${want}'), left as is"
    fi
}

__rayrc_install() {
    __rayrc_module_common_setup

    if [[ -d "${__rayrc_data_dir}/gitstatus" ]]; then
        (
            cd "${__rayrc_data_dir}/gitstatus" && git pull --quiet >&/dev/null
        )
    else
        git clone --quiet --depth 1 "https://github.com/romkatv/gitstatus.git" \
            "${__rayrc_data_dir}/gitstatus" >&/dev/null
    fi

    # git aliases
    __rayrc_git_config_ensure alias.st status
    __rayrc_git_config_ensure alias.co checkout
    __rayrc_git_config_ensure alias.cm commit
    __rayrc_git_config_ensure alias.b branch
    __rayrc_git_config_ensure alias.lg1 "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)' --all"
    __rayrc_git_config_ensure alias.lg2 "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(bold yellow)%d%C(reset)%n''          %C(white)%s%C(reset) %C(dim white)- %an%C(reset)' --all"
    __rayrc_git_config_ensure alias.lg '!git lg1'

    ## It's awful when it doesn't do what we want it to do.
    ##   https://www.youtube.com/watch?v=2c8wK2jkcIA
    __rayrc_git_config_ensure pull.rebase false

    __rayrc_git_config_ensure credential.helper store

    ## リモートのブランチから作ったとき、名前が同じ場合だけ追跡先を自動で付けるようになります。
    __rayrc_git_config_ensure branch.autoSetupMerge simple
    __rayrc_git_config_ensure push.autoSetupRemote true

    # echo ""
    # echo "  start updating submodules.."
    # (cd ${__rayrc_root_dir} && git submodule update --init --recursive --depth 1)
}

__rayrc_install
unset -f __rayrc_install __rayrc_git_config_ensure
