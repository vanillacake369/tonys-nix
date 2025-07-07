{ config, pkgs, ... }: {
  home.username = "limjihoon";
  home.homeDirectory = "/home/limjihoon";
  home.stateVersion = "23.11"; # Don't change after first setup

  # Applied keybindings :: https://heywoodlh.io/nixos-gnome-settings-and-keyboard-shortcuts
  dconf.settings = {
    "org/gnome/settings-daemon/plugins/media-keys" = {
        volume-up = [ "<Ctrl><Alt>Up" ];
        volume-down = [ "<Ctrl><Alt>Down" ];
        next = [ "<Shift><Control>n" ];
        previous = [ "<Shift><Control>p" ];
        play = [ "<Shift><Control>space" ];
        custom-keybindings = [
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom5/"
        ];
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
        name = "gnome console";
        command = "kgx";
        binding = "<Ctrl><Alt>t";
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
        name = "intellij";
        command = "idea-ultimate";
        binding = "<Ctrl><Alt>i";
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2" = {
        name = "goland";
        command = "goland";
        binding = "<Ctrl><Alt>g";
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3" = {
        name = "google chrome";
        command = "google-chrome-stable";
        binding = "<Ctrl><Alt>c";
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4" = {
        name = "youtube music";
        command = "youtube-music";
        binding = "<Ctrl><Alt>m";
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom5" = {
        name = "Capture";
        command = "gnome-screenshot -i";
        binding = "<Super><Shift>s";
      };
      # Disable workspace switching with Ctrl+Alt+Up/Down
      "org/gnome/desktop/wm/keybindings" = {
        switch-to-workspace-up = [ ];
        switch-to-workspace-down = [ ];
        switch-to-workspace-left = [ ];
        switch-to-workspace-right = [ ];
        # switch-to-workspace-down = [ "<Ctrl><Shift><Alt>Up" ];
        # switch-to-workspace-down = [ "<Ctrl><Shift><Alt>Down" ];
        # switch-to-workspace-left = [ "<Ctrl><Shift><Alt>Left" ];
        # switch-to-workspace-right = [ "<Ctrl><Shift><Alt>Right" ];
      };
  };
}
