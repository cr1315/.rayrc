#!/usr/bin/env bash

__rayrc_install() {
    __rayrc_module_common_setup


    case "${__rayrc_facts_os_type}" in
        linux*)
            curl -k -fsL "https://packages.httpie.io/binaries/linux/http-latest" --create-dirs \
                -o "${__rayrc_bin_dir}/http" >&/dev/null
            chmod +x "${__rayrc_bin_dir}/http"
            ;;

        macos*)
            brew install httpie
            ;;

        *)
            __rayrc_log_warn "could not retrieve binary for ${__rayrc_package:3}.."
            return 8
            ;;
    esac

}

__rayrc_install
unset -f __rayrc_install
