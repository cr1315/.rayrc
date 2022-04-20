# why

Recently I found that I'm working on newly created linux workstations so often that time by time I'm annoyed with these repeating work:  

- set up my shell aliaes, prompts, color schemas and custom functions, etc..
- install and configure my favorite [`bat`](https://github.com/sharkdp/bat), [`jq`](https://github.com/stedolan/jq), [`fzf`](https://github.com/junegunn/fzf), [`rg`](https://github.com/BurntSushi/ripgrep), [`fd`](https://github.com/sharkdp/fd), etc..
- install and configure vim plugins..

IT'S TIME to automate all of this with **one command**!

# what

It's supposed to inlucde all the modifications I've done to the machine.  
Yes, all the modifications.  

- Why? (You may ask)
- Well, you know, kind of, company policies, security blahblah..

Anyway, I'll try my best to include all my modifications with inside the `$HOME/.rayrc` folder.  

And finally, after installtion, it gives me a consistent shell environment as usual, whenever I log in, whichever workstation I log in to.

## features

Something like:
- beautiful and useful prompt
    - for Linux  
    ![beautiful and useful prompt](./docs/images/linux-prompt-with-git-status.png)
    - for Mac  

- auto-completion for frequently using commands
    - aws, k(kubectl), d(docker), dp(docker-compose).. 

- some useful custom functions
    - k.conf..


# who

## for me, and for all
I created this for myself, but I expect this to work for anyone who wants a somehow beautiful and useful shell environment.

## some prerequisites

- for linux, we assume the shell to be the standard bash
- for macos, we assume the shell to be the standard zsh
- and besides of this repo, we expect you to do some customizations for your terminal environment:  
    - one somehow nowadays terminal? Like [Windows Terminal](https://docs.microsoft.com/en-us/windows/terminal/install) on Win, [iTerm2](https://iterm2.com/) on Mac..
    - [Nerd Fonts:](https://www.nerdfonts.com/) beautiful monospace fonts with highly crafted icons..  
    - some colorschemas, like [Solarized](https://ethanschoonover.com/solarized/)..

It should be easy to setup, as easy as executing a single command -- `source .rayrc/install.sh`, and it would be excellent if I could delete all my custom setup with a single command, still making it better, creating something like `source .rayrc/uninstall.sh`.

# how

## installation for Unix

```
git clone https://github.com/cr1315/.rayrc.git && source .rayrc/install
```

## installation for Windows (on working..)

```
git clone https://github.com/cr1315/.rayrc.git && . .rayrc/install.ps1
```

## architecture

It may sounds ridiculous to use the word "architecutre"..  
Whatever, I think you can understand THE MOMENT you see this folder structure:  

- base folder
```
├── README.md
├── bash
├── docs
├── install
├── install.ps1
├── libs
├── powershell
├── test
├── uninstall
├── uninstall.ps1
└── zsh
```

- bash folder
```
bash
├── 00_bin
├── 05_package
├── 06_bat
├── 06_fd
├── 06_jq
├── 06_rg
├── 06_yq
├── 10_bash
├── 11_git
├── 40_docker
├── 49_ranger
├── 51_vim
├── 52_fzf
├── 60_aws
├── 61_terraform
├── 62_kubectl
├── 80_hulft
├── 90_misc
├── install.sh
└── main.sh
```

- zsh folder
```
zsh
├── 05_raypm
├── 10_zsh
├── 11_fzf
├── 12_git
├── 15_vim
├── 20_bat
├── install.zsh
├── main.zsh
└── uninstall.zsh
```

- libs dolers
```
libs
├── bat
├── bin
├── fd
├── fzf
├── git
├── jq
├── rg
├── vim
├── yq
└── zsh
```

# some pricipals

- idempotency
