{
  pkgs,
  lib,
  isWsl,
  isDarwin,
  isLinux,
  ...
}: {
  home.packages = with pkgs;
    [
      # Common packages for all platforms
      asciinema
      asciinema-agg
      awscli2
      ssm-session-manager-plugin
      bat
      jq
      git
      lazygit
      curl
      tree
      ripgrep
      neofetch
      lsof
      zellij
      htop
      btop
      autossh
      redli
      smartmontools
      expect
    ]
    ++ lib.optionals isLinux [
      # Linux (both native and WSL)
      xclip
      openssh
      psmisc
    ]
    ++ lib.optionals (isLinux && !isWsl) [
      # Native Linux only (not WSL)
      google-authenticator
      wayland-utils
    ]
    ++ lib.optionals isWsl [
      # WSL-specific packages
    ]
    ++ lib.optionals isDarwin [
      # macOS-specific packages
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
