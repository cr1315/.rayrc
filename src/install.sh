#!/usr/bin/env bash

## THERE IS NO REASON TO WRITE UGLY CODE!!!
## Yes, coding is hard, as we all know! -> It's why we call good code an artifact!

######################################################################
#
# Main
#
######################################################################
__rayrc_delegate_install() {
    echo ""
    __rayrc_source_facade install
    __rayrc_bootstrap_rc
}

######################################################################
# pre main
######################################################################
## TODO(remove after 2027-Q2): bash/ zsh/ powershell/ were merged into src/.
## After `git pull` on an existing host, those dirs keep only untracked leftovers
## (generated files, empty dirs). Remove one only when git says it has no tracked
## files, and only when .rayrc itself is the repository (not a tarball, and not a
## sub dir of some other repo such as a dotfiles repo, where ls-files is empty too).
__rayrc_cleanup_legacy_ctl() {
    command -v git >/dev/null 2>&1 || return 0

    local toplevel
    toplevel="$(git -C "${__rayrc_root_dir}" rev-parse --show-toplevel 2>/dev/null)" || return 0
    [[ "$(cd -- "${toplevel}" && pwd -P)" == "${__rayrc_root_dir}" ]] || return 0

    local old tracked
    for old in bash zsh powershell; do
        [[ -d "${__rayrc_root_dir}/${old}" ]] || continue
        tracked="$(git -C "${__rayrc_root_dir}" ls-files -- "${old}")" || continue
        [[ -z "${tracked}" ]] || continue

        rm -rf "${__rayrc_root_dir:?}/${old}"
        __rayrc_log_info "removed the old control plane dir ${old}/ (merged into src/)"
    done
}

######################################################################
# post main
######################################################################
__rayrc_bootstrap_rc() {
    ### after all installation completed, register main.sh in the .bashrc (managed block)
    [[ -f "$HOME/.bashrc" ]] || : >"$HOME/.bashrc"
    if ! __rayrc_rc_block "$HOME/.bashrc" \
        "[[ -f \"${__rayrc_main_dir}/main.sh\" ]] && source \"${__rayrc_main_dir}/main.sh\""; then
        __rayrc_log_warn "failed to register .rayrc in $HOME/.bashrc"
        return 8
    fi

    echo ""
    __rayrc_log_info "all done!"
    __rayrc_log_info "please logout & login again to enjoy your new shell environment!"
    echo ""
}

######################################################################
#
# Entry
#
######################################################################
## pre main
__rayrc_delegate_entry() {
    ## parameters
    local __rayrc_prms
    __rayrc_prms=("$@")
    local __rayrc_yes_no

    ## dir
    local __rayrc_main_dir
    __rayrc_main_dir="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
    # echo "\${__rayrc_main_dir}: ${__rayrc_main_dir}"

    local __rayrc_root_dir
    __rayrc_root_dir="$(cd -- "${__rayrc_main_dir}/.." && pwd -P)"
    local __rayrc_libs_dir
    ## maybe someone will install .rayrc to / ???
    __rayrc_libs_dir="$(cd -- "${__rayrc_root_dir}/libs" && pwd -P)"

    local __rayrc_bin_dir
    __rayrc_bin_dir="${__rayrc_libs_dir}/bin"
    # echo "\${__rayrc_bin_dir}: ${__rayrc_bin_dir}"
    if [[ ! -d "${__rayrc_bin_dir}" ]]; then
        mkdir -p "${__rayrc_bin_dir}"
    fi

    local __rayrc_ctl_dir
    local __rayrc_data_dir

    ## for packages
    local __rayrc_package

    source "${__rayrc_main_dir}/common.sh"

    __rayrc_cleanup_legacy_ctl

    local __rayrc_install_filter=()
    __rayrc_parse_args

    ## __rayrc_facts
    local __rayrc_facts_os_type
    local __rayrc_facts_os_distribution
    local __rayrc_package_manager
    local __rayrc_pm_update_repo

    __rayrc_determine_os_type
    unset -f __rayrc_determine_os_type

    __rayrc_determin_os_distribution
    unset -f __rayrc_determin_os_distribution
    # echo "\${__rayrc_facts_os_type}: ${__rayrc_facts_os_type}"
    # echo "\${__rayrc_facts_os_distribution}: ${__rayrc_facts_os_distribution}"
    # echo "\${__rayrc_package_manager}: ${__rayrc_package_manager}"

    __rayrc_delegate_install
}

__rayrc_delegate_entry "$@"

unset -f __rayrc_module_common_setup
unset -f __rayrc_source_facade __rayrc_list_modules
unset -f __rayrc_parse_args
unset -f __rayrc_sed_inplace
unset -f __rayrc_rc_block
unset -f __rayrc_install_binary __rayrc_place_binary
unset -f __rayrc_cleanup_legacy_ctl
unset -f __rayrc_bootstrap_rc
unset -f __rayrc_delegate_install
unset -f __rayrc_delegate_entry
