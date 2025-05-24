{ pkgs, ... }: {

  home.packages = with pkgs; [
    google-chrome
    jetbrains.idea-ultimate
    jetbrains.goland
    youtube-music
    ticktick
    slack
    firefox
    libreoffice
    hunspell
    hunspellDicts.en_US
    hunspellDicts.ko_KR
    hunspellDicts.ko-kr
    drawio
    openvpn
    openvpn3
    discord
  ];

  programs.git = {
    enable = true;
    userName  = "limjihoon";
    userEmail = "lonelynight1026@gmail.com";
  };
}

