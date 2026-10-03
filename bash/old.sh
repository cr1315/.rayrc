#!/usr/bin/env bash
## Obsolete parameter-parsing logic — kept for reference only.
## These functions are no longer called from the install flow.

__rayrc_populate_arrays() {
    local i
    local j

    local __rayrc_install_filters
    declare -a __rayrc_install_filters
    local __rayrc_enable_filters
    declare -a __rayrc_enable_filters
    local __rayrc_disable_filters
    declare -a __rayrc_disable_filters

    for ((i = 0; i < "${#__rayrc_prms[@]}"; i++)); do
        case "${__rayrc_prms[$i]}" in
        --install)
            i=$((i + 1))
            __rayrc_install_filters=(${__rayrc_prms[$i]//,/ })
            ;;
        --enable)
            i=$((i + 1))
            __rayrc_enable_filters=(${__rayrc_prms[$i]//,/ })
            ;;
        --disable)
            i=$((i + 1))
            __rayrc_disable_filters=(${__rayrc_prms[$i]//,/ })
            ;;
        *)
            __rayrc_print_help
            ;;
        esac
    done

    __rayrc_filter_packages
    __rayrc_enable_packages
    __rayrc_disable_packages
}

__rayrc_filter_packages() {
    local filter_matched
    if [[ "${#__rayrc_install_filters[@]}" -gt 0 ]]; then
        for ((i = 0; i < "${#__rayrc_all_packages[@]}"; i++)); do
            __rayrc_package="${__rayrc_all_packages[$i]}"
            filter_matched=false

            for ((j = 0; j < "${#__rayrc_install_filters[@]}"; j++)); do
                if [[ "${__rayrc_package}" == *"${__rayrc_install_filters[$j]}" ]]; then
                    filter_matched=true
                    break
                fi
            done

            if [[ "${filter_matched}" == "true" ]]; then
                __rayrc_packages_to_install+=("${__rayrc_package}")
            fi
        done
    else
        __rayrc_packages_to_install=("${__rayrc_all_packages[@]}")
    fi
}

__rayrc_enable_packages() {
    local filter_matched
    if [[ "${#__rayrc_enable_filters[@]}" -gt 0 ]]; then
        for ((i = 0; i < "${#__rayrc_all_packages[@]}"; i++)); do
            __rayrc_package="${__rayrc_all_packages[$i]}"
            filter_matched=false

            for ((j = 0; j < "${#__rayrc_enable_filters[@]}"; j++)); do
                if [[ "${__rayrc_package}" == *"${__rayrc_enable_filters[$j]}" ]]; then
                    filter_matched=true
                    break
                fi
            done

            if [[ "${filter_matched}" == "true" && -f "${__rayrc_main_dir}/${__rayrc_package}/disabled" ]]; then
                rm -f "${__rayrc_main_dir}/${__rayrc_package}/disabled"
            fi
        done
    fi
}

__rayrc_disable_packages() {
    local filter_matched
    if [[ "${#__rayrc_disable_filters[@]}" -gt 0 ]]; then
        for ((i = 0; i < "${#__rayrc_all_packages[@]}"; i++)); do
            __rayrc_package="${__rayrc_all_packages[$i]}"
            filter_matched=false

            for ((j = 0; j < "${#__rayrc_disable_filters[@]}"; j++)); do
                if [[ "${__rayrc_package}" == *"${__rayrc_disable_filters[$j]}" ]]; then
                    filter_matched=true
                    break
                fi
            done

            if [[ "${filter_matched}" == "true" && ! -f "${__rayrc_main_dir}/${__rayrc_package}/disabled" ]]; then
                touch "${__rayrc_main_dir}/${__rayrc_package}/disabled"
            fi
        done
    fi
}

__rayrc_print_help() {
    echo "If you don't want to bother, just run this line:"
    echo "  ~/.rayrc/install"
    echo ""
    echo "However, by default, we don't install eza (a cool tool that can replace \`ls'),"
    echo "if you want to include it, you can do like this:"
    echo "  ~/.rayrc/install --enable eza"
    echo ""
    echo "If you've already installed and is using .rayrc now, and you want to separately"
    echo "install a package, maybe eza?"
    echo "  ~/.rayrc/install --enable eza --install eza"
}
