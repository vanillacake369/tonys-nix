{ lib, pkgs, config, ... }: 
{
  # Enable Home Manager
  programs.home-manager.enable = true;

  # Import all modularized configurations
  imports = [
    # Command runner
    ./modules/pkgs/just-pkgs.nix
    ./modules/pkgs/lua-pkgs.nix

    # Podman & K8S for rootless container
    # ./modules/pkgs/podman-pkgs.nix
    ./modules/pkgs/kubernetes-pkgs.nix

    # Ollama
    ./modules/pkgs/ollama-pkgs.nix

    # Development Tools
    ./modules/pkgs/java-pkgs.nix
    ./modules/pkgs/k6-pkgs.nix

    # AWS
    ./modules/pkgs/aws-pkgs.nix
    
    # Shell setup
    ./modules/pkgs/zsh-pkgs.nix
    ./modules/pkgs/nvim-pkgs.nix
    ./modules/pkgs/asciinema-pkgs.nix
    ./modules/pkgs/jq-pkgs.nix
    ./modules/pkgs/ssh-pkgs.nix
  ];

}
