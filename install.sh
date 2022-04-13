# it would be best to be runnable on windows, linux and macos
# well, a bit difficult maybe..
#   first, no function? since function in bash/zsh is different from powershell
#   then, there is no $OS_TYPE in windows, 
#     but fortunetely, powershell variables start from `$`
#     but unfortunetely, the test statement is different between windows and linux
#     it would be difficult to write a script runnable on windows, linux and macos
#     maybe I should at least separate windows from others two
#     or, how about using a template engine -> dynamically generate the script to be executed
#       or, separate the install.sh and install.ps1 -> well, I think it's a good idea
#       at least, as far as I know, tomcat do it like this


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
    echo "__rayrc_install_dir: ${__rayrc_install_dir}"

    # echo "\$HOME: $HOME"
    # ls -ahl $HOME

    # echo "##### .bash_profile #####"
    # cat $HOME/.bash_profile
    # echo "##### .bashrc #####"
    # cat $HOME/.bashrc

    # echo "##### .bash_history #####"
    # cat $HOME/.bash_history

    # echo "##### .gitconfig #####"
    # cat $HOME/.gitconfig

	if [[ "$OSTYPE" == "linux-gnu"* ]]; then
		# determine if EC2 instance
		# sudo dmidecode --string system-uuid
		# cat /sys/hypervisor/uuid
		# TODO: case
		source "${__rayrc_install_dir}/linux/install.sh"
	elif [[ "$OSTYPE" == "darwin"* ]]; then
		source "${__rayrc_install_dir}/macos/install.zsh"
	else
		echo ".rayrc: not supportted OS by now.."
	fi
}


__rayrc_install
unset -f __rayrc_install
