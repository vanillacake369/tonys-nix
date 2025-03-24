# Intoduction

This repo is my personal setup for any linux distro based system using flakes and home manager.

This consist of these following packages

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
