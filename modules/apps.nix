{ pkgs, ... }: {

  home.packages = with pkgs; [
    google-chrome
    jetbrains.idea-ultimate
    jetbrains.goland
    vscode
    youtube-music
    ticktick
    slack
    firefox
    libreoffice
    hunspell
    hunspellDicts.en_US
    hunspellDicts.ko_KR
    hunspellDicts.ko-kr
    obsidian
  ];

  programs.git = {
    enable = true;
    userName  = "limjihoon";
    userEmail = "lonelynight1026@gmail.com";
  };
}

