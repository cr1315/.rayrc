#!/usr/bin/env zsh

__rayrc_somehow_global_functions() {
    true
}

__rayrc_delegate_install() {
    local __rayrc_package_manager
    local __rayrc_bin_dir

    local __rayrc_delegate_dir
    __rayrc_delegate_dir=$1
    # echo "\${__rayrc_delegate_dir}: ${__rayrc_delegate_dir}"

    local __rayrc_root_dir
    __rayrc_root_dir="$(cd -- "${__rayrc_delegate_dir}/.." && pwd -P)"
    local __rayrc_libs_dir
    __rayrc_libs_dir="$(cd -- "${__rayrc_delegate_dir}/../libs" && pwd -P)"

    local __rayrc_ctl_dir
    local __rayrc_data_dir
    source "${__rayrc_delegate_dir}/module_common_setup.sh"

    # determine the os type and set __rayrc_facts_os_type
    local __rayrc_facts_os_type
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        __rayrc_facts_os_type="linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        __rayrc_facts_os_type="macos"
    else
        echo ""
        echo ".rayrc: not supported OS type for now.."
        echo ""
        return 8
    fi

    local __rayrc_facts_os_distribution
    #
    # would be better to determine if this is an EC2 instance, photon OS, ubuntu, CentOS
    #
    # for EC2:
    #   `sudo dmidecode --string system-uuid'
    #   `cat /sys/hypervisor/uuid'
    # TODO: case switch
    #       set __rayrc_facts_os_distribution
    #
    # or, create a function __rayrc_determin_os_distribution()
    #

    ### auto setup
    echo ""
    local __rayrc_package
    for __rayrc_package in $(ls -1 "${__rayrc_delegate_dir}"); do
        # echo "\${__rayrc_delegate_dir}/\${__rayrc_package}: ${__rayrc_delegate_dir}/${__rayrc_package}"
        if [[ -d "${__rayrc_delegate_dir}/${__rayrc_package}" &&
            -f "${__rayrc_delegate_dir}/${__rayrc_package}/install.zsh" &&
            ! -f "${__rayrc_delegate_dir}/${__rayrc_package}/disabled" ]]; then
            # echo "\${__rayrc_delegate_dir}/\${__rayrc_package}: ${__rayrc_delegate_dir}/${__rayrc_package}"

            echo ".rayrc: setting up for ${__rayrc_package:3}.."
            source "${__rayrc_delegate_dir}/${__rayrc_package}/install.zsh"
        fi
    done

    ### after all installation completed, setup the .zshrc
    ### can we assume grep installed?
    if [[ -f "$HOME/.zshrc" ]]; then
        if grep -q '.rayrc' "$HOME/.zshrc"; then
            # we assume sed installed..
            sed -i -e '/\.rayrc.*main\.sh/ d' "$HOME/.zshrc"
        fi

        # use here document to add two lines
        "cat" <<EOF >>$HOME/.zshrc

[[ -f "${__rayrc_delegate_dir}/main.zsh" ]] && source "${__rayrc_delegate_dir}/main.zsh"
EOF

        # "cat" $HOME/.zshrc
        echo ""
        echo ".rayrc: all done!"
        echo ".rayrc: please logout & login to enjoy your new shell environment!"
    fi

}

__rayrc_delegate_install ${0:A:h}
unset -f __rayrc_delegate_install
