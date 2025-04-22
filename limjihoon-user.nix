{ ... }: {
  home.username = "limjihoon";
  home.homeDirectory = "/home/limjihoon";
  home.stateVersion = "23.11"; # Don't change after first setup
  dconf.settings = {
    "org/gnome/settings-daemon/plugins/media-keys" = {
        next = [ "<Shift><Control>n" ];
        previous = [ "<Shift><Control>p" ];
        play = [ "<Shift><Control>space" ];
        custom-keybindings = [
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
        ];
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
        name = "kgx";
        command = "kgx";
        binding = "<Ctrl><Alt>t";
      };
  };
}
