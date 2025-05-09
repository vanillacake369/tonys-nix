# Intoduction

This repo is my personal setup for any linux distro based system using flakes and home manager.

This consist of these following packages

```md
agg-1.5.0
asciinema-2.4.0
awscli2-2.26.4
bash-interactive-5.2p37
bash-interactive-5.2p37-man
bat-0.25.0
curl-8.12.1-bin
curl-8.12.1-man
fzf-0.61.2
fzf-0.61.2-man
git-2.49.0
go-1.24.2
gradle-8.13
hm-session-vars.sh
home-configuration-reference-manpage
home-manager
jq-1.7.1-bin
jq-1.7.1-man
just-1.40.0
just-1.40.0-man
k6-0.57.0
k9s-0.50.3
kubectl-1.32.3
kubectl-1.32.3-man
kubectl-tree-0.4.3
kubectx-0.9.5
kubernetes-helm-3.17.3
lua-5.2.4
man-db-2.13.0
minikube-1.34.0
neofetch-unstable-2021-12-10
neofetch-unstable-2021-12-10-man
neovim-0.11.0
nix-zsh-completions-0.5.1
oh-my-zsh-2025-04-13
openssh-9.9p2
powerlevel10k-1.20.14
ripgrep-14.1.1
screen-5.0.0
shared-mime-info-2.4
ssm-session-manager-plugin-1.2.707.0
stern-1.32.0
tree-2.2.1
vimplugin-vim-visual-multi-2024-09-01
xclip-0.13
yazi-25.4.8
zsh-5.9
zsh-5.9-man
zsh-autoenv-unstable-2017-12-16
zulu-ca-jdk-17.0.12
```

# Guidelines

> I've wrote about Nix Tutorial on [my post](https://velog.io/@vanillacake369/Nix-Tutorial)
>
> You can get much more deeper infos on there.
>
> If you're not familiar with korean, plz turn on google translation 😅

## Prerequisite

It would be lovely if you have [just](https://github.com/casey/just) already in your linux distro.

If you have one, follow [setup-configuration](https://github.com/vanillacake369/nix-tutorial#setup-configuration) step, and simply command `just` on root directory of this repo.

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

1. Create your own ${username}.nix file like this

`modules/user.nix`
```nix
# Replace username, homeDirectory
{ ... }: {
  home.username = "${username}";
  home.homeDirectory = "${homeDirectory}";
  home.stateVersion = "23.11"; # Don't change after first setup
}
```

2. Fix ${system}, and add your own ${username}.nix in homeConfigurations

`justfile`
```nix
{
  ,,,

  outputs = { self, nixpkgs, home-manager, system-manager, ... }:
    let
      
      ,,,

      # Fix system based on your arch of linux distro
      system = ${system};
      # system = "x86_64-linux";
      
      ,,,

    in {
      # Define the home configuration
      homeConfigurations = {
        ${username}= home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ 
            ./home.nix
            ./${your user configuration path}.nix
          ];
        };
      };

      ,,,
    };
}
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



# Help me! Minikube not able to ran on podman ! 😭

I'm willing to help for those who've undergo the same issue as I was.

If you're in a situation like this, plz follow the guidelines.

```sh
I0325 19:59:01.584962   25996 cli_runner.go:164] Run: podman container inspect -f {{.Id}} minikube
W0325 19:59:01.780690   25996 cli_runner.go:211] podman container inspect -f {{.Id}} minikube returned with exit code 125
I0325 19:59:01.780740   25996 cli_runner.go:164] Run: podman version --format {{.Version}}
I0325 19:59:02.016209   25996 cli_runner.go:164] Run: podman network inspect minikube --format "{{range .}}{{if eq .Driver "bridge"}}{{(index .Subnets 0).Subnet}},{{(index .Subnets 0).Gateway}}{{end}}{{end}}"
I0325 19:59:02.256393   25996 cli_runner.go:164] Run: podman network rm minikube
W0325 19:59:02.501754   25996 out.go:270] 🤦  StartHost failed, but will try again: creating host: create: creating: create kic node: container name "minikube": log: 2025-03-25T19:58:31.500324000+09:00 [0;1;31mFailed to create /init.scope control group: Permission denied[0m
2025-03-25T19:58:31.500394000+09:00 [0;1;31mFailed to allocate manager object: Permission denied[0m
2025-03-25T19:58:31.500450000+09:00 [[0;1;31m!!!!!![0m] Failed to allocate manager object.
2025-03-25T19:58:31.500515000+09:00 [0;1;31mExiting PID 1...[0m: container exited unexpectedly
```

## Reason/Solution

### Missing dependencies

Podman requires these in order to make it right.

If you've missed any, podman won't be able to create minikube container for you.

```nix
cni
dbus ## this should be running on systemd inside your system
qemu # required for `podman machine init`
virtiofsd # required for `podman machine init`
crun # required for Podman OCI runtime
runc # required for minikube requiring containerd
```

For cni plugin, you can follow [this guideline](https://sarc.io/index.php/cloud/2366-broken-network-functionality-for-cni-plugins#google_vignette) as well.

### Cgroup must be enabled and should be v2

Check your current cgroup [How do I check cgroup v2 is installed on my machine?](https://unix.stackexchange.com/questions/471476/how-do-i-check-cgroup-v2-is-installed-on-my-machine)

```sh
grep cgroup /proc/filesystems
```

If you're on wsl2, the default cgroup version is v1.

You should follow [this guideline](https://stackoverflow.com/questions/73021599/how-to-enable-cgroup-v2-in-wsl2)

```sh
[wsl2]
kernelCommandLine = cgroup_no_v1=all
```

### Check mount filesystem

```sh
sudo mount --make-rshared /
```

### Last but not least,,, log & make assumption with your own hypothesis

I'd like to advice you to log it first.


```sh
minikube logs --file=logs.txt
```

In my case, I've found podman couldn't create minikube container, and kept retrying.

The core issuee was dbus not running on systemd.

(I was on wsl2 , and after re-install everything solved my problem. )

```md
I0325 19:58:30.825542   25996 cli_runner.go:164] Run: podman run -d -t --privileged --security-opt seccomp=unconfined --tmpfs /tmp --tmpfs /run -v /lib/modules:/lib/modules:ro --hostname minikube --name minikube --label created_by.minikube.sigs.k8s.io=true --label name.minikube.sigs.k8s.io=minikube --label role.minikube.sigs.k8s.io= --label mode.minikube.sigs.k8s.io=minikube --network minikube --ip 192.168.49.2 --volume minikube:/var:exec --memory=3900mb -e container=podman --expose 8443 --publish=127.0.0.1::8443 --publish=127.0.0.1::22 --publish=127.0.0.1::2376 --publish=127.0.0.1::5000 --publish=127.0.0.1::32443 gcr.io/k8s-minikube/kicbase:v0.0.45
I0325 19:58:31.351209   25996 cli_runner.go:164] Run: podman container inspect minikube --format={{.State.Running}}
I0325 19:58:31.637436   25996 retry.go:31] will retry after 13.83625ms: temporary error created container "minikube" is not running yet
I0325 19:58:31.651972   25996 cli_runner.go:164] Run: podman container inspect minikube --format={{.State.Running}}
I0325 19:58:35.577161   25996 cli_runner.go:217] Completed: podman container inspect minikube --format={{.State.Running}}: (3.925164502s)
I0325 19:58:35.577184   25996 retry.go:31] will retry after 18.852255ms: temporary error created container "minikube" is not running yet
I0325 19:58:35.596544   25996 cli_runner.go:164] Run: podman container inspect minikube --format={{.State.Running}}
```

So I'd recommend you to log minikube, and compare the success case.

Here's my [success log](https://drive.google.com/file/d/1A0jV8h8gtTF3QWs43nlj4-AHPlik8Mke/view?usp=sharing)


# Help yourself ! 😋

Now enjoy diving into big lake of nix modules/flakes !

If any nix magician would like to make advice or improvement , plz feel free to make issue :-)
