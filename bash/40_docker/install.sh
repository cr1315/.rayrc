#!/usr/bin/env bash

command -v docker >/dev/null 2>&1 || { return; }

# __rayrc_install() {
#     __rayrc_module_common_setup

#     case "${__rayrc_facts_os_type}-`uname -m`" in
#         linux-arm* | linux-aarch*)
#             __rayrc_github_downloader \
#                 "docker/compose" "${__rayrc_data_dir}/docker-compose" \
#                 "linux" 'aarch64"'
#             ;;
#         linux-*86* | linux-*ia64*)
#             __rayrc_github_downloader \
#                 "docker/compose" "${__rayrc_data_dir}/docker-compose" \
#                 "linux" 'x86_64"'
#             ;;
#         macos-arm* | macos-aarch*)
#             __rayrc_github_downloader \
#                 "docker/compose" "${__rayrc_data_dir}/docker-compose" \
#                 "darwin" 'aarch64"'
#             ;;
#         macos-*86* | macos-*ia64*)
#             __rayrc_github_downloader \
#                 "docker/compose" "${__rayrc_data_dir}/docker-compose" \
#                 "darwin" 'x86_64"'
#             ;;
#         *)
#             echo ".rayrc: could not retrieve binary for ${__rayrc_package:3}.."
#             return 8
#             ;;
#     esac

#     if [[ $? -ne 0 ]]; then
#         echo "  .rayrc: failed to setup ${__rayrc_package:3}"
#         return 8
#     fi


#     DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
#     mkdir -p $DOCKER_CONFIG/cli-plugins
#     # curl -SL https://github.com/docker/compose/releases/download/v5.0.0/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose
#     chmod +x "${__rayrc_data_dir}/docker-compose"
#     cp -f "${__rayrc_data_dir}/docker-compose" "${DOCKER_CONFIG}/cli-plugins/docker-compose"

#     rm -rf "${__rayrc_data_dir}/docker-compose"*
# }

# __rayrc_install
# unset -f __rayrc_install
