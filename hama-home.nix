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
    ./modules/pkgs/kubernetes-pkgs.nix

    # Development Tools
    ./modules/pkgs/java-pkgs.nix
    ./modules/pkgs/go-pkgs.nix
    ./modules/pkgs/k6-pkgs.nix
    ./modules/pkgs/lazydocker-pkgs.nix
    ./modules/pkgs/mise-pkgs.nix

    # AWS
    ./modules/pkgs/aws-pkgs.nix
    
    # Shell setup
    ./modules/pkgs/nvim-pkgs.nix
    ./modules/pkgs/asciinema-pkgs.nix
    ./modules/pkgs/jq-pkgs.nix
    ./modules/pkgs/ripgrep-pkgs.nix
    ./modules/pkgs/tree-pkgs.nix
    ./modules/pkgs/bat-pkgs.nix
    ./modules/pkgs/eza-pkgs.nix
    ./modules/pkgs/xclip-pkgs.nix
    ./modules/pkgs/screen-pkgs.nix
  ];

}
