let
  standardUnless = [
    "^com\\.apple\\.Terminal$"
    "^com\\.googlecode\\.iterm2$"
    "^com\\.github\\.wez\\.wezterm$"
    "^io\\.alacritty$"
    "^net\\.kovidgoyal\\.kitty$"
    "^com\\.jetbrains\\..*$"
    "^com\\.knollsoft\\.Rectangle$"
  ];
  browsers = ["^com\\.google\\.Chrome$" "^com\\.brave\\.Browser$"];
in {
  workspaces = {
    Docs = {
      monitor = 1;
      apps = ["Obsidian"];
    };
    Code = {
      monitor = 2;
      apps = ["com.jetbrains.intellij" "com.jetbrains.goland" "com.jetbrains.datagrip"];
    };
    Browser = {
      monitor = 2;
      apps = browsers;
    };
    Terminal = {
      monitor = 3;
      apps = ["com.github.wez.wezterm" "Docker Desktop" "Podman Desktop"];
    };
    Music = {
      monitor = 3;
      apps = ["YouTube Music"];
    };
    Schedule = {
      monitor = 3;
      apps = ["TickTick"];
    };
  };

  settings = {
    gaps = {
      inner = 12;
      outer = 12;
    };
    floating_apps = [
      "System Settings"
      "Finder"
      "Karabiner"
      "Photos"
      "App Store"
      "Preview"
      "Horo"
      "Notes"
      "FaceTime"
      "AppCleaner"
      "Shottr"
      "Discord"
      "Opal"
      "KakaoTalk"
    ];
  };

  keymaps = [
    # --- System core ---
    {
      bind = "caps_lock";
      to_if_alone = ["escape" {select_input_source = "en";}];
      to_if_held = ["hyper"];
      optional = ["any"];
      tags = ["karabiner"];
      description = "Capslock to Hyper(Held) / Esc + En(Alone)";
    }
    {
      bind = "right_command";
      to = "f18";
      tags = ["karabiner"];
    }
    {
      bind = "cmd+l";
      to = "cmd+ctrl+q";
      tags = ["karabiner"];
      unless = browsers;
    }
    {
      bind = "cmd+m";
      to = [];
      tags = ["karabiner"];
    }
    {
      bind = "cmd+spacebar";
      shell = "open -a 'Raycast'";
      tags = ["karabiner"];
    }

    # --- Karabiner: hyper+hjkl -> arrow keys (Vim cursor) ---
    {
      bind = "hyper+h";
      to = "left_arrow";
      tags = ["karabiner"];
    }
    {
      bind = "hyper+j";
      to = "down_arrow";
      tags = ["karabiner"];
    }
    {
      bind = "hyper+k";
      to = "up_arrow";
      tags = ["karabiner"];
    }
    {
      bind = "hyper+l";
      to = "right_arrow";
      tags = ["karabiner"];
    }
    {
      bind = "hyper+u";
      to = "page_up";
      tags = ["karabiner"];
    }
    # NOTE: hyper+d is aerospace-only (workspace Docs). No karabiner page_down here to avoid conflict.

    # --- AeroSpace: cmd+hyper+hjkl -> window focus ---
    {
      bind = "cmd+hyper+h";
      exec = "focus left";
      tags = ["aerospace"];
    }
    {
      bind = "cmd+hyper+j";
      exec = "focus down";
      tags = ["aerospace"];
    }
    {
      bind = "cmd+hyper+k";
      exec = "focus up";
      tags = ["aerospace"];
    }
    {
      bind = "cmd+hyper+l";
      exec = "focus right";
      tags = ["aerospace"];
    }

    # --- AeroSpace: shift+hyper+hjkl -> move window ---
    {
      bind = "shift+hyper+h";
      exec = "move left";
      tags = ["aerospace"];
    }
    {
      bind = "shift+hyper+j";
      exec = "move down";
      tags = ["aerospace"];
    }
    {
      bind = "shift+hyper+k";
      exec = "move up";
      tags = ["aerospace"];
    }
    {
      bind = "shift+hyper+l";
      exec = "move right";
      tags = ["aerospace"];
    }

    # --- AeroSpace: arrow key backup ---
    {
      bind = "hyper+left_arrow";
      exec = "focus left";
      tags = ["aerospace"];
    }
    {
      bind = "hyper+down_arrow";
      exec = "focus down";
      tags = ["aerospace"];
    }
    {
      bind = "hyper+up_arrow";
      exec = "focus up";
      tags = ["aerospace"];
    }
    {
      bind = "hyper+right_arrow";
      exec = "focus right";
      tags = ["aerospace"];
    }
    {
      bind = "cmd+hyper+left_arrow";
      exec = "move left";
      tags = ["aerospace"];
    }
    {
      bind = "cmd+hyper+down_arrow";
      exec = "move down";
      tags = ["aerospace"];
    }
    {
      bind = "cmd+hyper+up_arrow";
      exec = "move up";
      tags = ["aerospace"];
    }
    {
      bind = "cmd+hyper+right_arrow";
      exec = "move right";
      tags = ["aerospace"];
    }

    # --- AeroSpace: workspace switch ---
    {
      bind = "hyper+c";
      exec = "workspace Code";
      tags = ["aerospace"];
    }
    {
      bind = "hyper+d";
      exec = "workspace Docs";
      tags = ["aerospace"];
    }
    {
      bind = "hyper+m";
      exec = "workspace Music";
      tags = ["aerospace"];
    }
    {
      bind = "hyper+s";
      exec = "workspace Schedule";
      tags = ["aerospace"];
    }
    {
      bind = "hyper+t";
      exec = "workspace Terminal";
      tags = ["aerospace"];
    }
    {
      bind = "hyper+b";
      exec = "workspace Browser";
      tags = ["aerospace"];
    }

    # --- AeroSpace: move window to workspace ---
    {
      bind = "cmd+hyper+c";
      exec = ["move-node-to-workspace Code" "workspace Code"];
      tags = ["aerospace"];
    }
    {
      bind = "cmd+hyper+d";
      exec = ["move-node-to-workspace Docs" "workspace Docs"];
      tags = ["aerospace"];
    }
    {
      bind = "cmd+hyper+m";
      exec = ["move-node-to-workspace Music" "workspace Music"];
      tags = ["aerospace"];
    }
    {
      bind = "cmd+hyper+s";
      exec = ["move-node-to-workspace Schedule" "workspace Schedule"];
      tags = ["aerospace"];
    }
    {
      bind = "cmd+hyper+t";
      exec = ["move-node-to-workspace Terminal" "workspace Terminal"];
      tags = ["aerospace"];
    }
    {
      bind = "cmd+hyper+b";
      exec = ["move-node-to-workspace Browser" "workspace Browser"];
      tags = ["aerospace"];
    }

    # --- AeroSpace: monitor focus & move ---
    {
      bind = "hyper+1";
      exec = "focus-monitor 1";
      tags = ["aerospace"];
    }
    {
      bind = "hyper+2";
      exec = "focus-monitor 2";
      tags = ["aerospace"];
    }
    {
      bind = "hyper+3";
      exec = "focus-monitor 3";
      tags = ["aerospace"];
    }
    {
      bind = "cmd+hyper+1";
      exec = ["move-node-to-monitor 1" "focus-monitor 1"];
      tags = ["aerospace"];
    }
    {
      bind = "cmd+hyper+2";
      exec = ["move-node-to-monitor 2" "focus-monitor 2"];
      tags = ["aerospace"];
    }
    {
      bind = "cmd+hyper+3";
      exec = ["move-node-to-monitor 3" "focus-monitor 3"];
      tags = ["aerospace"];
    }

    # --- AeroSpace: utilities ---
    {
      bind = "hyper+tab";
      exec = "workspace-back-and-forth";
      tags = ["aerospace"];
    }
    {
      bind = "cmd+hyper+tab";
      exec = "move-workspace-to-monitor --wrap-around next";
      tags = ["aerospace"];
    }
    {
      bind = "hyper+semicolon";
      exec = "mode service";
      tags = ["aerospace"];
    }
    {
      bind = "hyper+spacebar";
      exec = "fullscreen";
      tags = ["aerospace"];
    }
    {
      bind = "hyper+hyphen";
      exec = "resize smart -50";
      tags = ["aerospace"];
    }
    {
      bind = "hyper+equal_sign";
      exec = "resize smart +50";
      tags = ["aerospace"];
    }
    {
      bind = "hyper+slash";
      exec = "layout tiles horizontal vertical";
      tags = ["aerospace"];
    }
    {
      bind = "hyper+comma";
      exec = "layout accordion horizontal vertical";
      tags = ["aerospace"];
    }

    # --- Karabiner: Ctrl -> Cmd (Windows/Linux style) ---
    {
      bind = "ctrl+a";
      to = "cmd+a";
      tags = ["karabiner"];
      unless = standardUnless;
    }
    {
      bind = "ctrl+c";
      to = "cmd+c";
      tags = ["karabiner"];
      unless = standardUnless;
    }
    {
      bind = "ctrl+v";
      to = "cmd+v";
      tags = ["karabiner"];
      unless = standardUnless;
    }
    {
      bind = "ctrl+x";
      to = "cmd+x";
      tags = ["karabiner"];
      unless = standardUnless;
    }
    {
      bind = "ctrl+z";
      to = "cmd+z";
      tags = ["karabiner"];
      unless = standardUnless;
    }
    {
      bind = "ctrl+s";
      to = "cmd+s";
      tags = ["karabiner"];
      unless = standardUnless;
    }
    {
      bind = "ctrl+f";
      to = "cmd+f";
      tags = ["karabiner"];
      unless = standardUnless;
    }
    {
      bind = "ctrl+t";
      to = "cmd+t";
      tags = ["karabiner"];
      unless = standardUnless;
    }
    {
      bind = "ctrl+w";
      to = "cmd+w";
      tags = ["karabiner"];
      unless = standardUnless;
    }
    {
      bind = "ctrl+y";
      to = "cmd+y";
      tags = ["karabiner"];
      unless = standardUnless;
    }
    {
      bind = "ctrl+o";
      to = "cmd+o";
      tags = ["karabiner"];
      unless = standardUnless;
    }
    {
      bind = "ctrl+p";
      to = "cmd+p";
      tags = ["karabiner"];
      unless = standardUnless;
    }
    {
      bind = "ctrl+g";
      to = "cmd+g";
      tags = ["karabiner"];
      unless = standardUnless;
    }
    {
      bind = "ctrl+l";
      to = "cmd+l";
      tags = ["karabiner"];
      unless = standardUnless;
    }
    {
      bind = "ctrl+q";
      to = "cmd+q";
      tags = ["karabiner"];
      unless = standardUnless;
    }
    {
      bind = "ctrl+slash";
      to = "cmd+slash";
      tags = ["karabiner"];
      unless = standardUnless;
    }

    # --- Karabiner: cursor word jump (Ctrl -> Option) ---
    {
      bind = "ctrl+left_arrow";
      to = "option+left_arrow";
      tags = ["karabiner"];
      unless = standardUnless;
      condition = {
        type = "variable_unless";
        name = "capslock_held";
        value = 1;
      };
    }
    {
      bind = "ctrl+right_arrow";
      to = "option+right_arrow";
      tags = ["karabiner"];
      unless = standardUnless;
      condition = {
        type = "variable_unless";
        name = "capslock_held";
        value = 1;
      };
    }
    {
      bind = "ctrl+shift+left_arrow";
      to = "option+shift+left_arrow";
      tags = ["karabiner"];
      unless = standardUnless;
      condition = {
        type = "variable_unless";
        name = "capslock_held";
        value = 1;
      };
    }
    {
      bind = "ctrl+shift+right_arrow";
      to = "option+shift+right_arrow";
      tags = ["karabiner"];
      unless = standardUnless;
      condition = {
        type = "variable_unless";
        name = "capslock_held";
        value = 1;
      };
    }
    {
      bind = "ctrl+delete_or_backspace";
      to = "option+delete_or_backspace";
      tags = ["karabiner"];
      unless = standardUnless;
    }
    {
      bind = "ctrl+delete_forward";
      to = "option+delete_forward";
      tags = ["karabiner"];
      unless = standardUnless;
    }

    # --- Karabiner: Home/End keys ---
    {
      bind = "home";
      to = "cmd+left_arrow";
      tags = ["karabiner"];
      unless = browsers;
    }
    {
      bind = "end";
      to = "cmd+right_arrow";
      tags = ["karabiner"];
      unless = browsers;
    }
    {
      bind = "shift+home";
      to = "cmd+shift+left_arrow";
      tags = ["karabiner"];
      unless = browsers;
    }
    {
      bind = "shift+end";
      to = "cmd+shift+right_arrow";
      tags = ["karabiner"];
      unless = browsers;
    }
    {
      bind = "ctrl+home";
      to = "cmd+up_arrow";
      tags = ["karabiner"];
      unless = browsers;
    }
    {
      bind = "ctrl+end";
      to = "cmd+down_arrow";
      tags = ["karabiner"];
      unless = browsers;
    }

    # --- Karabiner: browser-only shortcuts ---
    {
      bind = "cmd+e";
      to = "cmd+l";
      tags = ["karabiner"];
      only = browsers;
    }
    {
      bind = "ctrl+e";
      to = "cmd+l";
      tags = ["karabiner"];
      only = browsers;
    }
    {
      bind = "ctrl+h";
      to = "cmd+h";
      tags = ["karabiner"];
      only = browsers;
    }
    {
      bind = "ctrl+shift+w";
      to = "cmd+shift+w";
      tags = ["karabiner"];
      only = browsers;
    }
    {
      bind = "ctrl+shift+t";
      to = "cmd+shift+t";
      tags = ["karabiner"];
      only = browsers;
    }
    {
      bind = "ctrl+n";
      to = "cmd+n";
      tags = ["karabiner"];
      only = browsers;
    }
    {
      bind = "ctrl+shift+n";
      to = "cmd+shift+n";
      tags = ["karabiner"];
      only = browsers;
    }
    {
      bind = "ctrl+k";
      to = "cmd+k";
      tags = ["karabiner"];
      only = browsers;
    }
    {
      bind = "ctrl+j";
      to = "cmd+j";
      tags = ["karabiner"];
      only = browsers;
    }
    {
      bind = "ctrl+d";
      to = "cmd+d";
      tags = ["karabiner"];
      only = browsers;
    }
    {
      bind = "ctrl+shift+d";
      to = "cmd+shift+d";
      tags = ["karabiner"];
      only = browsers;
    }
    {
      bind = "ctrl+r";
      to = "cmd+r";
      tags = ["karabiner"];
      only = browsers;
    }
    {
      bind = "ctrl+shift+r";
      to = "cmd+shift+r";
      tags = ["karabiner"];
      only = browsers;
    }
    {
      bind = "ctrl+u";
      to = "cmd+u";
      tags = ["karabiner"];
      only = browsers;
    }
    {
      bind = "ctrl+shift+c";
      to = "cmd+shift+c";
      tags = ["karabiner"];
      only = browsers;
    }
    {
      bind = "ctrl+b";
      to = "cmd+b";
      tags = ["karabiner"];
      only = browsers;
    }
    {
      bind = "ctrl+i";
      to = "cmd+i";
      tags = ["karabiner"];
      only = browsers;
    }
    {
      bind = "ctrl+shift+u";
      to = "cmd+u";
      tags = ["karabiner"];
      only = browsers;
    }
    {
      bind = "ctrl+shift+s";
      to = "cmd+shift+s";
      tags = ["karabiner"];
      only = browsers;
    }
    {
      bind = "ctrl+l";
      to = "cmd+l";
      tags = ["karabiner"];
      only = browsers;
    }
    {
      bind = "ctrl+0";
      to = "cmd+0";
      tags = ["karabiner"];
      only = browsers;
    }
    {
      bind = "ctrl+equal_sign";
      to = "cmd+equal_sign";
      tags = ["karabiner"];
      only = browsers;
    }
    {
      bind = "ctrl+hyphen";
      to = "cmd+hyphen";
      tags = ["karabiner"];
      only = browsers;
    }
    {
      bind = "ctrl+shift+delete_forward";
      to = "cmd+shift+delete_forward";
      tags = ["karabiner"];
      only = browsers;
    }
    {
      bind = "f5";
      to = "cmd+r";
      tags = ["karabiner"];
      only = browsers;
    }
    {
      bind = "ctrl+f5";
      to = "cmd+shift+r";
      tags = ["karabiner"];
      only = browsers;
    }

    # --- Karabiner: browser tab navigation ---
    {
      bind = "cmd+left_arrow";
      to = "cmd+option+left_arrow";
      tags = ["karabiner"];
      only = browsers;
    }
    {
      bind = "cmd+right_arrow";
      to = "cmd+option+right_arrow";
      tags = ["karabiner"];
      only = browsers;
    }
    {
      bind = "ctrl+1";
      to = "cmd+1";
      tags = ["karabiner"];
      only = browsers;
    }
    {
      bind = "ctrl+2";
      to = "cmd+2";
      tags = ["karabiner"];
      only = browsers;
    }
    {
      bind = "ctrl+3";
      to = "cmd+3";
      tags = ["karabiner"];
      only = browsers;
    }
    {
      bind = "ctrl+4";
      to = "cmd+4";
      tags = ["karabiner"];
      only = browsers;
    }
    {
      bind = "ctrl+5";
      to = "cmd+5";
      tags = ["karabiner"];
      only = browsers;
    }
    {
      bind = "ctrl+6";
      to = "cmd+6";
      tags = ["karabiner"];
      only = browsers;
    }
    {
      bind = "ctrl+7";
      to = "cmd+7";
      tags = ["karabiner"];
      only = browsers;
    }
    {
      bind = "ctrl+8";
      to = "cmd+8";
      tags = ["karabiner"];
      only = browsers;
    }
    {
      bind = "ctrl+9";
      to = "cmd+9";
      tags = ["karabiner"];
      only = browsers;
    }

    # --- Karabiner: app launchers ---
    {
      bind = "ctrl+cmd+t";
      shell = "open -a 'WezTerm'";
      tags = ["karabiner"];
    }
    {
      bind = "ctrl+cmd+m";
      shell = "open '/Users/limjihoon/Applications/Brave Browser Apps.localized/YouTube Music.app'";
      tags = ["karabiner"];
      unless = ["^com\\.jetbrains\\..*$" "^com\\.knollsoft\\.Rectangle$"];
    }
    {
      bind = "ctrl+cmd+b";
      shell = "open -a 'Brave Browser'";
      tags = ["karabiner"];
    }
    {
      bind = "ctrl+cmd+i";
      shell = "open -a 'IntelliJ IDEA'";
      tags = ["karabiner"];
    }
    {
      bind = "ctrl+cmd+g";
      shell = "open -a 'GoLand'";
      tags = ["karabiner"];
    }
    {
      bind = "ctrl+cmd+s";
      shell = "open -a 'TickTick'";
      tags = ["karabiner"];
    }
    {
      bind = "ctrl+cmd+d";
      shell = "open -a 'Obsidian'";
      tags = ["karabiner"];
    }
  ];
}
