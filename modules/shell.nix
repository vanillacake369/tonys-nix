{ pkgs, lib, isWsl, ... }: 

with pkgs;

{
  home.packages = [
    asciinema
    asciinema-agg   
    awscli2
    ssm-session-manager-plugin
    bat
    jq
    git
    curl 
    bash
    tree
    ripgrep
    openssh
    xclip
    neofetch
    lsof
    psmisc
    wayland-utils
    zellij
    htop
  ] ++ lib.optionals (!isWsl) [
    vagrant
  ];

  programs = {
    yazi = {
      enable = true;
      enableZshIntegration = true;
      shellWrapperName = "y";
      theme = {
        filetype = {
          rules = [
            { fg = "#7AD9E5"; mime = "image/*"; }
            { fg = "#F3D398"; mime = "video/*"; }
            { fg = "#F3D398"; mime = "audio/*"; }
            { fg = "#CD9EFC"; mime = "application/bzip"; }
          ];
        };  
      };
    };
  };
}

