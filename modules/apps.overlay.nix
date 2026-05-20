# Wayland optimizations for Chrome and Slack (Linux only, applied globally is safe — no-op on Darwin)
final: prev: {
  google-chrome = prev.google-chrome.override {
    commandLineArgs = "--ozone-platform-hint=auto --enable-wayland-ime --enable-features=TouchpadOverscrollHistoryNavigation --wayland-text-input-version=3";
  };
  slack = final.symlinkJoin {
    name = "slack";
    paths = [prev.slack];
    buildInputs = [final.makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/slack \
        --add-flags "--ozone-platform-hint=auto --enable-wayland-ime --enable-features=TouchpadOverscrollHistoryNavigation --wayland-text-input-version=3"
    '';
  };
}
