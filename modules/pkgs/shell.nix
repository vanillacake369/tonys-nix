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
}

