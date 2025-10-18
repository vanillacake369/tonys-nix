{...}: {
  # GNOME desktop environment settings via dconf
  # Applied keybindings :: https://heywoodlh.io/nixos-gnome-settings-and-keyboard-shortcuts

  dconf.settings = {
    # Touchpad configuration for GNOME/Wayland
    "org/gnome/desktop/peripherals/touchpad" = {
      # Cursor/pointer speed: -1.0 (slowest) to 1.0 (fastest)
      speed = 0.3;

      # Scroll speed multiplier: higher = slower scrolling
      # Default is 1.0, try 2.0-5.0 for much slower scrolling
      scroll-factor = 3.0;

      # Tap to click
      tap-to-click = true;
      tap-and-drag = true;
      tap-and-drag-lock = false;

      # Natural scrolling (macOS-style: reversed)
      natural-scroll = true;

      # Two-finger scrolling
      two-finger-scrolling-enabled = true;
      edge-scrolling-enabled = false;

      # Disable touchpad while typing
      disable-while-typing = true;

      # Click method: "default", "none", "areas", "fingers"
      click-method = "fingers"; # Clickfinger style (like macOS)

      # Tap button mapping
      tap-button-map = "default"; # "default" or "lmr" (left, middle, right)

      # Middle click emulation
      middle-click-emulation = false;

      # Acceleration profile: "default", "flat", "adaptive"
      accel-profile = "flat"; # Disable acceleration for precision
    };

    # Mouse configuration (for external mouse)
    "org/gnome/desktop/peripherals/mouse" = {
      # Mouse speed
      speed = 0.3;

      # Disable mouse acceleration for precision
      accel-profile = "flat";

      # Natural scroll for mouse
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
