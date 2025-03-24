# Intoduction

This repo is my personal setup for any linux distro based system using flakes and home manager.

This consist of these following packages

```md
asciinema-2.4.0
bash-interactive-5.2p37
bash-interactive-5.2p37-man
curl-8.12.1-bin
curl-8.12.1-man
fzf-0.60.3
fzf-0.60.3-man
git-2.48.1
hm-session-vars.sh
home-configuration-reference-manpage
home-manager
jq-1.7.1-bin
jq-1.7.1-man
just-1.39.0
just-1.39.0-man
k9s-0.40.5
kubectl-1.32.2
kubectl-1.32.2-man
kubectl-tree-0.4.3
kubectx-0.9.5
kubernetes-helm-3.17.1
man-db-2.13.0
minikube-1.34.0
neovim-0.10.4
nix-zsh-completions-0.5.1
oh-my-zsh-2025-02-19
powerlevel10k-1.20.14
shared-mime-info-2.4
stern-1.32.0
vimplugin-vim-visual-multi-2024-09-01
zsh-5.9
zsh-5.9-man
zsh-autoenv-unstable-2017-12-16
```

# Guidelines

> My personal post on Nix Tutorial is on [my post](https://velog.io/@vanillacake369/Nix-Tutorial)
>
> If you're not familiar with korean, plz turn on google translation 😅

## Prerequisite

If you can, it would be lovely if you have [just](https://github.com/casey/just) already in your linux distro.

If you have one, simply command `just` on root directory of this repo.

Everything will be done within justfile for you 😉.

But if you don't, why not ! Just follow the short term journey :-)

## Install Nix

Based on [this document](https://nixos.org/download/),,,

> Multi-User
```sh
sh <(curl -L https://nixos.org/nix/install) --daemon
```

> Single-User
```sh
sh <(curl -L https://nixos.org/nix/install) --no-daemon
```

## Install Home manager

Based on [this document](https://nix-community.github.io/home-manager/index.xhtml#ch-installation),,,

If you are following Nixpkgs master or an unstable channel you can run

```sh
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
nix-channel --update
```

and if you follow a Nixpkgs version 24.11 channel you can run

```sh
nix-channel --add https://github.com/nix-community/home-manager/archive/release-24.11.tar.gz home-manager
nix-channel --update
```

Run the Home Manager installation command and create the first Home Manager generation:

```sh
nix-shell '<home-manager>' -A install
```

If you do not plan on having Home Manager manage your shell configuration then you must source the

```sh
$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh
```

file in your shell configuration.


## Setup configuration

### Fix username and os

You need to fix your username and os in order to correctly use this.

`modules/user.nix`
```nix
# Replace username, homeDirectory
{ ... }: {
  home.username = "${username}";
  home.homeDirectory = "${homeDirectory";
  home.stateVersion = "23.11"; # Don't change after first setup
}
```

`justfile`
```nix
,,,

# Replace username
install:
  home-manager switch --flake .#limjihoon -b back

,,,
```

### Command manually, and after that utilize just command :-)

I'd like to use `just` command over `make`.

Why ? It's just my thing.

Simple, no phony target, programmable with almost all languges, so why no to that!

So behalf of that, setting up this configuration requires just command, as I've told you before.

```sh
home-manager switch --flake .#limjihoon -b back

nix-collect-garbage -d

exec zsh
```

After this, everything you need will be installed.

If you'd like to utilize package installation at just one command, command `just`.

It'll all settle up just for you, like its named of.


# Help yourself ! 😋

Now enjoy diving into big lake of nix modules/flakes !

If any nix magician would like to make advice or improvement , plz feel free to make issue :-)
