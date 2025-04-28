{ pkgs, ... }: {
  home.packages = with pkgs; [
    asciinema
    asciinema-agg   
    awscli2
    ssm-session-manager-plugin
    bat
    jq
    k6
    git
    curl 
    bash
    vimPlugins.vim-visual-multi
    tree
    ripgrep
    screen
    openssh
    xclip
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

