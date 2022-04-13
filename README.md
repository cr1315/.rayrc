# pricipal

## 冪等性

自分用のモノだけど、今のPCでのみ機能する訳じゃいけない  


# why

Recently I found that I often need to work on some new linux workstations, time by time I'll have to set up my aliaes, prompts, color schemas and custom functions, and download and install my favorite fzf, rg, fd, etc..  
Annoyed with the repeating work, so I created this rc repo and put it on the cloud.  

# what

It's desired to automate all the stuff above, giving me a consistent rc environment whenever I log in, whichever workstation I log in to.

## features

Specifically, it includes some features like:
- beautiful and useful prompt
    - ![beautiful and useful prompt](./docs/images/linux-prompt-with-git-status.png)
- auto-completion for frequently using commands
    - aws, k(kubectl), d(docker), dp(docker-compose).. 
- some useful custom functions
    - k.conf..


# who

## some assumptions 

- for linux, we assume the shell to be the standard bash
- for macos, we assume the shell to be the standard zsh




It should be easy to setup, as easy as executing a single command -- `source .rayrc/install.sh`, and it would be excellent if I could delete all my custom setup with a single command, still making it better, creating something like `source .rayrc/uninstall.sh`.

# where

## installation

```
git clone git@github.com:cr1315/.rayrc.git
. .rayrc/install.sh
```

# how

## architecture

It may sounds ridiculous to use the word "architecutre", whatever..  
I think you can understand it the moment you see the folder structure:  

```

```