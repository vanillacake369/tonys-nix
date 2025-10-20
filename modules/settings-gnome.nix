# NixOS-specific settings and configurations (GNOME desktop)
{
  lib,
  ...
}: {
  # =============================================================================
  # GNOME Desktop Settings (dconf)
  # =============================================================================
  dconf.settings = {
    # Touchpad configuration for GNOME/Wayland
    "org/gnome/desktop/peripherals/touchpad" = {
      speed = 0.3;
      scroll-factor = 3.0;
      tap-to-click = true;
      tap-and-drag = true;
      tap-and-drag-lock = false;
      natural-scroll = true;
      two-finger-scrolling-enabled = true;
      edge-scrolling-enabled = false;
      disable-while-typing = true;
      click-method = "fingers";
      tap-button-map = "default";
      middle-click-emulation = false;
      accel-profile = "custom";
    };

    # Mouse configuration
    "org/gnome/desktop/peripherals/mouse" = {
      speed = 0.3;
      accel-profile = "flat";
      natural-scroll = true;
    };

    # Media key bindings
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

    # Custom application launcher keybindings
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
    };

    # Power management and idle settings
    "org/gnome/desktop/session" = {
      idle-delay = 900;
    };

    "org/gnome/desktop/screensaver" = {
      lock-enabled = true;
      lock-delay = 0;
    };

    "org/gnome/settings-daemon/plugins/power" = {
      sleep-inactive-ac-type = "nothing";
      sleep-inactive-ac-timeout = 0;
      sleep-inactive-battery-type = "nothing";
      sleep-inactive-battery-timeout = 0;
      sleep-inactive-ac-blank-timeout = 0;
      sleep-inactive-battery-blank-timeout = 0;
      idle-dim = false;
      ambient-enabled = false;
      power-button-action = "interactive";
    };
  };

  # =============================================================================
  # Systemd Initiation
  # =============================================================================
  # Auto-start systemd user services
  systemd.user.startServices = "sd-switch";
}
