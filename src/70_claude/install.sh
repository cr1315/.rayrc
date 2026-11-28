#!/usr/bin/env bash

__rayrc_install() {
    __rayrc_module_common_setup

    ## ~/.claude → libs/claude/.claude, laid BEFORE the installer. The installer (its
    ## ~/.claude/downloads is hard-coded) and `claude install` (backups/, sessions/) write
    ## into ~/.claude, so linking afterwards backed up a dir the installer had just made.
    ## Anything that is not our link — a dir, a file, someone else's symlink, a dangling
    ## one — is kept as ~/.claude_rayrc_bkup_<timestamp> (same as install.ps1)
    local link="${HOME}/.claude"
    local target="${__rayrc_data_dir}/.claude"
    if [[ ! -L "${link}" || "$(readlink "${link}")" != "${target}" ]]; then
        if [[ -e "${link}" || -L "${link}" ]]; then
            mv "${link}" "${link}_rayrc_bkup_$(date +%Y%m%d_%H%M%S)"
        fi
        mkdir -p "${target}"
        ln -snf "${target}" "${link}"
    fi

    if [[ -x "${__rayrc_bin_dir}/claude" ]]; then
        "${__rayrc_bin_dir}/claude" update >&/dev/null || {
            echo "  .rayrc: failed to update claude"
        }
    fi

    ## bootstrap claude using its official installer
    (cd "${__rayrc_data_dir}" && curl -fsSL https://claude.ai/install.sh | bash >&/dev/null) || {
        echo "  .rayrc: failed to bootstrap claude"
        return 8
    }

    ## claude installs its binary to ~/.local/bin/claude — symlink into __rayrc_bin_dir
    if [[ -x "${HOME}/.local/bin/claude" ]]; then
        ln -snf "${HOME}/.local/bin/claude" "${__rayrc_bin_dir}/claude"
    fi

    ## probe Bedrock access only here, once per install; main.sh just checks the marker
    ## (probing on every shell startup piles up AccessDenied events in CloudTrail)
    if command -v aws >&/dev/null && \
       aws bedrock list-foundation-models --region ap-northeast-1 >&/dev/null; then
        touch "${__rayrc_data_dir}/use_bedrock"
    else
        rm -f "${__rayrc_data_dir}/use_bedrock"
    fi
}

__rayrc_install
unset -f __rayrc_install
