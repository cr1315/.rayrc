#!/usr/bin/env bash

## docker 本体は入れない（無ければ何もしない）
command -v docker >/dev/null 2>&1 || { return; }

__rayrc_install() {
    __rayrc_module_common_setup

    ## compose が既にあれば何もしない（v2 plugin / v1 standalone のどちらでも）
    if docker compose version &>/dev/null || command -v docker-compose &>/dev/null; then
        return
    fi

    ## 末尾の `"` は href の閉じ引用符にマッチさせるため
    ## これが無いと .sha256 / .sbom.json / .provenance.json / .sigstore.json も引っかかる
    case "${__rayrc_facts_os_type}-`uname -m`" in
        linux-arm*64* | linux-aarch*64*)
            __rayrc_github_downloader \
                "docker/compose" "${__rayrc_data_dir}/docker-compose" \
                "linux" 'aarch64"'
            ;;
        linux-armv7*)
            __rayrc_github_downloader \
                "docker/compose" "${__rayrc_data_dir}/docker-compose" \
                "linux" 'armv7"'
            ;;
        linux-armv6*)
            __rayrc_github_downloader \
                "docker/compose" "${__rayrc_data_dir}/docker-compose" \
                "linux" 'armv6"'
            ;;
        linux-*64*)
            __rayrc_github_downloader \
                "docker/compose" "${__rayrc_data_dir}/docker-compose" \
                "linux" 'x86_64"'
            ;;
        macos-arm* | macos-aarch*)
            __rayrc_github_downloader \
                "docker/compose" "${__rayrc_data_dir}/docker-compose" \
                "darwin" 'aarch64"'
            ;;
        macos-*86* | macos-*ia64*)
            __rayrc_github_downloader \
                "docker/compose" "${__rayrc_data_dir}/docker-compose" \
                "darwin" 'x86_64"'
            ;;
        *)
            __rayrc_log_warn "could not retrieve binary for docker compose.."
            return 8
            ;;
    esac

    if [[ $? -ne 0 ]]; then
        __rayrc_log_warn "failed to setup docker compose"
        return 8
    fi

    ## compose plugin だけは特殊: `docker compose` として認識させるには
    ## docker の cli-plugins ディレクトリに置く必要があるため、libs/bin ではなくここに入れる
    local plugin_dir="${DOCKER_CONFIG:-$HOME/.docker}/cli-plugins"
    mkdir -p "${plugin_dir}"
    chmod +x "${__rayrc_data_dir}/docker-compose"
    cp -f "${__rayrc_data_dir}/docker-compose" "${plugin_dir}/docker-compose"

    rm -rf "${__rayrc_data_dir}/docker-compose"*
}

__rayrc_install
unset -f __rayrc_install
