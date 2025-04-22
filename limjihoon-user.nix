{ config, pkgs, ... }: {
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
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4/"
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
  };

  xdg.desktopEntries = {
    google-chrome-stable = {
      name = "Chrome WebBrowser";
      exec = "google-chrome-stable --enable-wayland-ime --enable-features=TouchpadOverscrollHistoryNavigation";
      icon = "${pkgs.morewaita-icon-theme}/share/icons/MoreWaita/apps/scalable/com.google.Chrome.svg";
      genericName = "Web Browser";
      terminal = false;
      categories = [ "Application" "Network" "WebBrowser" ];
      mimeType = [ "text/html" "text/xml" ];
    };
  };
}
