#!/usr/bin/env bash

command -v claude >/dev/null 2>&1 || { return; }

## temporary workaround: the Claude Code VSCode extension's webview CSP lacks `font-src data:`,
## so the icons in the edited-file view don't render. Patch the latest installed extension once.
## Remove once fixed upstream.
__rayrc_patch_vscode_claude_csp() {
    local -r font_src_re='font-src \$\{[A-Za-z_$]+\.cspSource\}'
    local ext_root ext_dir ext_js

    for ext_root in "${HOME}/.vscode-server/extensions" "${HOME}/.vscode/extensions"; do
        ext_dir="$(ls -1d "${ext_root}"/anthropic.claude-code-*/ 2>/dev/null | sort -V | tail -n 1)"
        [[ -n "${ext_dir}" ]] || continue
        ext_js="${ext_dir%/}/extension.js"
        [[ -w "${ext_js}" ]] || continue

        ## already patched
        grep -qE "${font_src_re} data:" "${ext_js}" && continue

        if ! grep -qE "${font_src_re}" "${ext_js}"; then
            echo "  .rayrc: font-src not found in ${ext_js}; CSP patch skipped (maybe no longer needed)"
            continue
        fi

        if sed -i.bak -E "s/(${font_src_re})/\1 data:/" "${ext_js}"; then
            echo "  .rayrc: patched font-src CSP in ${ext_js} (reload the VSCode window)"
        else
            echo "  .rayrc: failed to patch font-src CSP in ${ext_js}"
        fi
    done
}

__rayrc_main() {
    __rayrc_module_common_setup

    __rayrc_patch_vscode_claude_csp

    if command -v aws >&/dev/null && \
       aws bedrock list-foundation-models --region ap-northeast-1 >&/dev/null; then
        export CLAUDE_CODE_USE_BEDROCK=1
        export AWS_REGION=ap-northeast-1
    fi

}

__rayrc_main
unset -f __rayrc_main __rayrc_patch_vscode_claude_csp
