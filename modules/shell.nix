{
  pkgs,
  lib,
  isWsl,
  isLinux,
  ...
}: {
  home.packages = with pkgs;
    [
      asciinema
      asciinema-agg
      awscli2
      ssm-session-manager-plugin
      bat
      jq
      git
      curl
      tree
      ripgrep
      neofetch
      lsof
      zellij
      htop
      autossh
      redli
      smartmontools
      expect
      psmisc
      xclip
      openssh
    ]
    ++ lib.optionals (isLinux && !isWsl) [
      # Linux desktop utilities (not WSL)
      google-authenticator
      wayland-utils
    ];

  programs = {
    git = {
      enable = true;
      userName = "limjihoon";
      userEmail = "lonelynight1026@gmail.com";
    };
    yazi = {
      enable = true;
      enableZshIntegration = true;
      shellWrapperName = "y";
      theme = {
        filetype = {
          rules = [
            {
              fg = "#7AD9E5";
              mime = "image/*";
            }
            {
              fg = "#F3D398";
              mime = "video/*";
            }
            {
              fg = "#F3D398";
              mime = "audio/*";
            }
            {
              fg = "#CD9EFC";
              mime = "application/bzip";
            }
          ];
        };
      };
    };
  };
}
