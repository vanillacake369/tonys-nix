final: prev: {
  # NOTE:
  # Chrome/Slack의 Wayland IME 플래그는 Linux GUI 세션의 입력 품질을 위해
  # package wrapper 계층에서 한 번만 주입한다. Darwin에는 해당 package가
  # 실질적으로 쓰이지 않으므로 overlay 전역 적용보다 호출부 분기가 더 비싸다.
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
