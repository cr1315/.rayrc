# for linux, we assume bash
# for macos, we assume zsh
# so, this script should be runnable on both <= it shouldn't be that difficult I think

# we don't have to use some specific shell to run this script I think,
# it just adds some lines into .zshrc or .bashrc


# TODO: 
#   1. determine the ostype
#   2. add some the start lines into .bashrc or .zshrc


__rayrc_install() {
    local __rayrc_install_dir
    __rayrc_install_dir="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
    # echo "__rayrc_install_dir: ${__rayrc_install_dir}"

    sed -Ei '/source.*\.rayrc\/main.sh/d' "$HOME/.bashrc"

    cat >>"$HOME/.bashrc" <<EOF
[[ -f "${__rayrc_install_dir}/main.sh" ]] && source "${__rayrc_install_dir}/main.sh"
EOF
}


__rayrc_install
unset -f __rayrc_install
