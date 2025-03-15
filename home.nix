{ lib, pkgs, ... }: 
let
  username = "limjihoon";
in
{
  home = {
    # user `inherit` to do same as `username = username;`
    inherit username;

    homeDirectory = "/home/${username}";

    # Install packages from https://search.nixos.org/packages
    packages = with pkgs; [
      # Says hello.  So helpful.
      hello
      # Rainbows and flakes in terminal. How lovely
      cowsay
      lolcat
      # Home Manager is available in shell
      home-manager
    ];

    file = {
      "hello.txt" = {
        text = ''
          echo "Hello, ${username}!"
          echo '*slaps roof* This script can fit so many lines in it'
        '';
        executable = true;
      };
    };
    
    # This needs to be set to your actual username.
    # username = "limjihoon";
    # homeDirectory = "/home/limjihoon";

    # Don't ever change this after the first build.
    # It tells home-manager what the original state schema
    # was, so it knows how to go to the next state.  It
    # should NOT update when you update your system!
    # stateVersion = "25.05";
    stateVersion = "23.11";

  };
}

