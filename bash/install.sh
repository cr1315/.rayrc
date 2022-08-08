#!/usr/bin/env bash

## well, but, THAT IS NOT A REASON TO NOT WRITE BEAUTIFUL CODE!!!
## coding is just a hard work! -> It's you who make it an artifact!

__rayrc_url_downloader() {
	true
}
unset -f __rayrc_url_downloader

######################################################################
# we'd like to install some famous, useful tools from github to this
# workstation..
######################################################################
__rayrc_github_downloader() {
	local bin_name
	local target_path

	bin_name="$1"
	target_path="$2"
	shift
	shift

	local release_links
	local downloaded_link

	## https://stackoverflow.com/questions/16703647/why-does-curl-return-error-23-failed-writing-body
	release_links="$(curl -sfL "https://github.com/${bin_name}/releases/latest")"
	release_links="$(echo "$release_links" | grep 'href="' | grep 'download/')"

	# while [[ `echo "$release_links" | wc -l` -gt 1 && -n "$1" ]]; do
	while [[ $(echo "$release_links" | wc -l) -gt 1 && ! "$1" =~ ^[[:space:]]*$ ]]; do
		release_links="$(echo "$release_links" | grep -E "$1")"
		shift
	done

	if [[ $(echo "$release_links" | wc -l) -ne 1 ]]; then
		echo "unable to extract download link for ${bin_name}:"
		echo "$release_links"
		return 8
	fi

	downloaded_link="$(echo "$release_links" | perl -pe's/.*(?<=href=")([^"]*).*/$1/')"
	# echo "https://github.com${downloaded_link}"
	curl -fsL "https://github.com${downloaded_link}" --create-dirs -o "${target_path}"
	return 0
}

######################################################################
#
#
#
######################################################################
__rayrc_delegate_install() {
	## declare global variables here
	##   as our goal is to do all the things on the fly, I'll try to EXPORT nothing in the implementation
	local __rayrc_package_manager
	local __rayrc_bin_dir

	local __rayrc_delegate_dir
	__rayrc_delegate_dir="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
	# echo "\${__rayrc_delegate_dir}: ${__rayrc_delegate_dir}"

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
	for package in $(ls -1 "${__rayrc_delegate_dir}"); do

		# echo "\${__rayrc_delegate_dir}/\${package}: ${__rayrc_delegate_dir}/${package}"
		if [[ -d "${__rayrc_delegate_dir}/${package}" && -f "${__rayrc_delegate_dir}/${package}/install.sh" ]]; then
			echo "  .rayrc: setting up for ${package:3}.."
			source "${__rayrc_delegate_dir}/${package}/install.sh"
		fi

	done

	### after all installation completed, setup the .bashrc
	if [[ -f "$HOME/.bashrc" ]]; then
		if grep -q '.rayrc' "$HOME/.bashrc"; then
			# we assume that sed is installed..
			sed -i -e '/\.rayrc.*main\.sh/ d' "$HOME/.bashrc"
		fi

		# use here document to add two lines
		"cat" <<EOF >>"$HOME/.bashrc"

[[ -f "${__rayrc_delegate_dir}/main.sh" ]] && source "${__rayrc_delegate_dir}/main.sh"
EOF

		# "cat" "$HOME/.bashrc"
		echo ""
		echo ".rayrc: all done!"
		echo ".rayrc: please logout & login to enjoy your new shell environment!"
		echo ""
	elif [[ -f "$HOME/.profile" ]]; then
		if grep -q '.rayrc' "$HOME/.profile"; then
			sed -i -e '/\.rayrc.*main\.sh/ d' "$HOME/.profile"
		fi

		"cat" <<EOF >>"$HOME/.profile"

[[ -f "${__rayrc_delegate_dir}/main.sh" ]] && source "${__rayrc_delegate_dir}/main.sh"
EOF

	else
		echo ""
		echo ".rayrc: both .bashrc and .profile not found.."
		echo ".rayrc: you may need to add this line to your profile file manually: "
		echo ""
		echo "[[ -f \"${__rayrc_delegate_dir}/main.sh\" ]] && source \"${__rayrc_delegate_dir}/main.sh\""
		echo ""
	fi
}

__rayrc_delegate_install
unset -f __rayrc_delegate_install
