{ lib, pkgs, ... }: 
{
  # Enable home-manager (Maybe,,?)
  programs.home-manager.enable = true;

  home = {
    # Install packages from https://search.nixos.org/packages
    packages = with pkgs; [
      # Says hello.  So helpful.
      hello
      # Zsh
      zsh
      zsh-autoenv
    ];
    
    # This needs to be set to your actual username.
    username = "limjihoon";
    homeDirectory = "/home/limjihoon";

    # Don't ever change this after the first build.
    # It tells home-manager what the original state schema
    # was, so it knows how to go to the next state.  It
    # should NOT update when you update your system!
    # stateVersion = "25.05";
    stateVersion = "23.11";
  };

  programs = {
    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;

      oh-my-zsh = {
        enable = true;
        plugins = ["git"];
        theme = "robbyrussell";
      };

      # Source zsh-autoenv manually
      initExtra = ''
      source ${pkgs.zsh-autoenv}/share/zsh-autoenv/autoenv.zsh
      '';
    };
  };
}

