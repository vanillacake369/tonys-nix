# Google Chrome overlay with Wayland optimizations
# Adds Wayland-specific flags for better GNOME integration
final: prev: {
  google-chrome = prev.google-chrome.override {
    commandLineArgs = "--ozone-platform-hint=auto --enable-wayland-ime --enable-features=TouchpadOverscrollHistoryNavigation --wayland-text-input-version=3";
  };
}
