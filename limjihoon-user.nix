{pkgs, ...}: {
  home.username = "limjihoon";
  home.homeDirectory =
    if pkgs.stdenv.isDarwin
    then "/Users/limjihoon"
    else "/home/limjihoon";
  home.stateVersion = "23.11"; # Don't change after first setup
}
