#!/usr/bin/env bash

# we would need to bring compiled bins to the workstation..
# then it would be boring to prepare for the target platform? CPU type? etc..

# well, but, THAT IS NOT A REASON TO NOT WRITE BEAUTIFUL CODE!!!
# at least, write beautiful code that would be worked as assumed!
# coding is just a hard work! -> It's you who make it an artifact!


__rayrc_url_downloader() {
	true
}


######################################################################
#
#
#
######################################################################
__rayrc_github_downloader() {
	local bin_name
	local target_path

	bin_name="$1"
	target_path="$2"
    shift; shift;

	local downloadable_links
	local downloaded_link


	# https://stackoverflow.com/questions/16703647/why-does-curl-return-error-23-failed-writing-body
	downloadable_links="$(curl -sfL "https://github.com/${bin_name}/releases/latest")"
	downloadable_links="$(echo "$downloadable_links" | grep 'href="' | grep 'download/')"

    # while [[ `echo "$downloadable_links" | wc -l` -gt 1 && -n "$1" ]]; do
    while [[ `echo "$downloadable_links" | wc -l` -gt 1 && ! "$1" =~ ^[[:space:]]*$ ]]; do
        downloadable_links="$(echo "$downloadable_links" | grep -E "$1")"
        shift;
    done


	if [[ `echo "$downloadable_links" | wc -l` -ne 1 ]]; then
		echo "unable to extract the exact download link for ${bin_name}:"
		echo "$downloadable_links"
		return 8
	fi


	downloaded_link="$(echo "$downloadable_links" | perl -pe's/.*(?<=href=")([^"]*).*/$1/')"
	# echo "https://github.com${downloaded_link}"
	curl -fsL "https://github.com${downloaded_link}" --create-dirs -o "${target_path}"
	return 0
}


######################################################################
#
#
#
######################################################################
__rayrc_delegate_install_bash() {
    local __rayrc_raypm
    local __rayrc_dir_shell

	local __rayrc_dir_data_bin

    __rayrc_dir_shell="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
    # echo "\${__rayrc_dir_shell}: ${__rayrc_dir_shell}"


    # determine the os type and set __rayrc_stat_os
	if [[ "$OSTYPE" == "linux-gnu"* ]]; then
		__rayrc_stat_os="linux"
	elif [[ "$OSTYPE" == "darwin"* ]]; then
		__rayrc_stat_os="macos"
	else
		echo ".rayrc: not supported OS by now.."
		return 8
	fi


	#
	# would be better to determine if this is an EC2 instance, photon OS, ubuntu, CentOS
	#
	# for EC2:
	#   `sudo dmidecode --string system-uuid'
	#   `cat /sys/hypervisor/uuid'
	# TODO: case switch
	#       set __rayrc_stat_os_dist


	### auto setup
	echo ""
	for package in `ls -1 "${__rayrc_dir_shell}"`; do

		# echo "\${__rayrc_dir_shell}/\${package}: ${__rayrc_dir_shell}/${package}"
		if [[ -d "${__rayrc_dir_shell}/${package}" && -f "${__rayrc_dir_shell}/${package}/install.sh" ]]; then
			echo "  .rayrc: setting up for ${package:3}.."
			source "${__rayrc_dir_shell}/${package}/install.sh"
		fi

	done


	### after all installation completed, setup the .bashrc
	### can we assume grep installed?
	if [[ -f "$HOME/.bashrc" ]]; then
		if grep -q '.rayrc' "$HOME/.bashrc"; then
			# we assume sed installed..
			sed -i -e '/\.rayrc.*main\.sh/ d' "$HOME/.bashrc"
		fi

# use here document to add two lines
"cat" <<EOF >> "$HOME/.bashrc"

[[ -f "${__rayrc_dir_shell}/main.sh" ]] && source "${__rayrc_dir_shell}/main.sh"
EOF

		#"cat" "$HOME/.bashrc"
		echo ""
		echo ".rayrc: all done!"
		echo ".rayrc: please logout & login to enjoy your new shell environment!"
	elif [[ -f "$HOME/.profile" ]]; then
		
# use here document to add two lines
"cat" <<EOF >> "$HOME/.profile"

[[ -f "${__rayrc_dir_shell}/main.sh" ]] && source "${__rayrc_dir_shell}/main.sh"
EOF

	else
		true
	fi

}


__rayrc_delegate_install_bash
unset -f __rayrc_delegate_install_bash
