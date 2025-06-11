{ pkgs, lib, isWsl, ... }: {

  home.packages = with pkgs; [
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
    neofetch
    lsof
    psmisc
    zellij
    htop
    xclip
  ] ++ lib.optionals (!isWsl) [
    openssh
    wayland-utils
    vagrant
    google-authenticator
  ];

  programs = {
    git = {
      enable = true;
      userName  = "limjihoon";
      userEmail = "lonelynight1026@gmail.com";
    };
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

