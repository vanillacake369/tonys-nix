{ lib, pkgs, config, ... }: 
{
  # Enable Home Manager
  programs.home-manager.enable = true;

  services.fusuma = {
    enable = true;
    extraPackages = with pkgs; [ xdotool ];
    settings = {
      threshold = { swipe = 0.1; };
      interval = { swipe = 0.7; };
      swipe = {
        "3" = {
          left = {
            # GNOME: Switch to left workspace
            command = "xdotool key ctrl+alt+Left";
          };
          right = {
            # GNOME: Switch to right workspace
            command = "xdotool key ctrl+alt+Right";
          };
        };
      };
    };
  };

  # Import all modularized configurations
  imports = [
    # Command runner
    ./modules/pkgs/just-pkgs.nix
    ./modules/pkgs/lua-pkgs.nix

    # Podman & K8S for rootless container
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
  ];

}
