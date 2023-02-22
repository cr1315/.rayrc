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
    ![beautiful and useful prompt](./docs/images/macos-prompt-with-git-status.png)

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

# how

It should be easy to setup, as easy as executing a single command:

## installation for Unix

```
git clone https://github.com/cr1315/.rayrc.git && source .rayrc/install
```

## installation for Windows (on working..)

```
git clone https://github.com/cr1315/.rayrc.git && . .rayrc/install.ps1
```

## for test

```
git clone -b dev_docker --single-branch --depth 1 https://github.com/cr1315/.rayrc.git && source .rayrc/install
```

## architecture

It may sounds ridiculous to use the word "architecutre"..  
Whatever, I think you can understand THE MOMENT you see this folder structure:

![beautiful and useful prompt](./docs/images/rayrc_architecture.png)

# some pricipals

I would assume that this repo could create a Terminal rc Pluggable Platform.

- unified management
- extensibility / pluggable
- idempotency
