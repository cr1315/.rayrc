#!/usr/bin/env bash

command -v atuin >/dev/null 2>&1 || { return; }

__rayrc_main() {
    __rayrc_module_common_setup

    ## Same self-contained dirs as install.sh so atuin reads config + history
    ## from libs/atuin at runtime.
    export ATUIN_CONFIG_DIR="${__rayrc_data_dir}/config"
    export ATUIN_DATA_DIR="${__rayrc_data_dir}/data"

    ## Shell integration (Ctrl-R history search + up-arrow). Modern atuin loads
    ## a bundled bash-preexec via __atuin_load_builtin_preexec when neither
    ## ble.sh nor bash-preexec is present, so no external preexec is required.
    ## Add --disable-up-arrow after "bash" to keep the shell's native up-arrow.
    eval "$(atuin init bash)"

    eval "$(atuin gen-completions --shell bash)" 2>/dev/null
}

__rayrc_main
unset -f __rayrc_main
