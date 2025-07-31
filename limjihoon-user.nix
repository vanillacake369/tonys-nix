{
  config,
  pkgs,
  ...
}: {
  home.username = "limjihoon";
  home.homeDirectory = "/home/limjihoon";
  home.stateVersion = "23.11"; # Don't change after first setup

  # Applied keybindings :: https://heywoodlh.io/nixos-gnome-settings-and-keyboard-shortcuts
  dconf.settings = {
    "org/gnome/settings-daemon/plugins/media-keys" = {
      volume-up = ["<Ctrl><Alt>Up"];
      volume-down = ["<Ctrl><Alt>Down"];
      next = ["<Shift><Control>n"];
      previous = ["<Shift><Control>p"];
      play = ["<Shift><Control>space"];
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
      name = "youtube music desktop";
      command = "ytmdesktop";
      binding = "<Ctrl><Alt>m";
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom5" = {
      name = "Capture";
      command = "gnome-screenshot -i";
      binding = "<Super><Shift>s";
    };
    # Disable workspace switching with Ctrl+Alt+Up/Down
    "org/gnome/desktop/wm/keybindings" = {
      switch-to-workspace-up = [];
      switch-to-workspace-down = [];
      switch-to-workspace-left = [];
      switch-to-workspace-right = [];
      # switch-to-workspace-down = [ "<Ctrl><Shift><Alt>Up" ];
      # switch-to-workspace-down = [ "<Ctrl><Shift><Alt>Down" ];
      # switch-to-workspace-left = [ "<Ctrl><Shift><Alt>Left" ];
      # switch-to-workspace-right = [ "<Ctrl><Shift><Alt>Right" ];
    };

    # Power management and idle settings
    "org/gnome/desktop/session" = {
      idle-delay = 900; # 15 minutes before considering system idle
    };

    "org/gnome/desktop/screensaver" = {
      lock-enabled = true;
      lock-delay = 0; # Lock immediately when screensaver activates
    };

    "org/gnome/settings-daemon/plugins/power" = {
      # AC power settings - never suspend on AC power
      sleep-inactive-ac-type = "nothing";
      sleep-inactive-ac-timeout = 0; # Never sleep

      # Battery power settings - never suspend on battery
      sleep-inactive-battery-type = "nothing";
      sleep-inactive-battery-timeout = 0; # Never sleep

      # Screen blanking settings - keep screen on
      sleep-inactive-ac-blank-timeout = 0; # Never blank screen on AC
      sleep-inactive-battery-blank-timeout = 0; # Never blank screen on battery

      # Disable screen dimming
      idle-dim = false; # Don't dim screen when idle
      ambient-enabled = false; # Disable adaptive brightness

      # Power button action
      power-button-action = "interactive"; # Show power off dialog
    };
  };
}
