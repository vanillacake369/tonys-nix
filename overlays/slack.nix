# Slack overlay with Wayland optimizations
# Wraps Slack with Wayland-specific flags for better GNOME integration
final: prev: {
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
