{ pkgs, ... }: {

  home.packages = with pkgs; [
    asciinema
    asciinema-agg   
    awscli2
    ssm-session-manager-plugin
    bat
    jq
    k6
    curl 
    bash
    tree
    ripgrep
    screen
    openssh
    xclip
  ];

  programs.git = {
    enable = true;
    userName  = "limjihoon";
    userEmail = "lonelynight1026@gmail.com";
  };
}

