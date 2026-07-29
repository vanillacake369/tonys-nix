{
  config,
  isDarwin,
  pkgs,
  ...
}: let
  zellijPluginDir = "${config.home.homeDirectory}/.config/zellij/plugins";
  zellijConfig = import ../../lib/mk-zellij-config.nix {
    inherit isDarwin;
    fishPath = "${pkgs.fish}/bin/fish";
    pluginDir = zellijPluginDir;
  };
  zestty = pkgs.stdenvNoCC.mkDerivation {
    pname = "zestty";
    version = "0.2.1";
    src = pkgs.fetchurl {
      url = "https://github.com/aidantlynch00/zestty/releases/download/v0.2.1/zestty";
      hash = "sha256-vGQ8vvzMX9TnTect7P5s2r5iAQqHk+Mqd40Sy3ady7o=";
    };
    dontUnpack = true;
    installPhase = ''
      install -Dm755 "$src" "$out/bin/zestty"
    '';
  };
in {
  home.packages = [
    zestty
  ];

  # NOTE:
  # zellij UI, helper scripts, wasm plugins, zestty bootstrap은 한 런타임 경계다.
  # 파일만 잘게 찢으면 activation 그래프는 얕아지지 않고 추적만 어려워진다.
  # 그래서 이 파일이 Home Manager entrypoint이자 terminal multiplexer bundle을
  # 직접 소유한다. 별도 shell entrypoint layer는 만들지 않는다.
  home.file = {
    ".config/zellij/config.kdl".text = zellijConfig;
    ".config/zellij/scripts/zellij-pane-picker" = {
      source = ../../dotfiles/zellij/scripts/zellij-pane-picker;
      executable = true;
    };
    ".config/zellij/scripts/zellij-context-toggle" = {
      source = ../../dotfiles/zellij/scripts/zellij-context-toggle;
      executable = true;
    };
    ".config/zellij/scripts/zellij-nav-dispatch" = {
      source = ../../dotfiles/zellij/scripts/zellij-nav-dispatch;
      executable = true;
    };
    ".config/zellij/scripts/zellij-nav-lib".source = ../../dotfiles/zellij/scripts/zellij-nav-lib;
    ".config/zellij/plugins/room.wasm".source = pkgs.fetchurl {
      url = "https://github.com/rvcas/room/releases/download/v1.2.1/room.wasm";
      hash = "sha256-kLSDpAt2JGj7dYYhYFh6BfvtzVwTrcs+0jHwG/nActE=";
    };
    ".config/zellij/plugins/zellij-forgot.wasm".source = pkgs.fetchurl {
      url = "https://github.com/karimould/zellij-forgot/releases/download/0.4.2/zellij_forgot.wasm";
      hash = "sha256-MRlBRVGdvcEoaFtFb5cDdDePoZ/J2nQvvkoyG6zkSds=";
    };
    ".config/zellij/plugins/zestty.wasm".source = pkgs.fetchurl {
      url = "https://github.com/aidantlynch00/zestty/releases/download/v0.2.1/zestty.wasm";
      hash = "sha256-AOBm2BUOuGtw6LwvD1acUEFqiKevKaqZ4vJ015yVOf8=";
    };
    ".config/zestty/config".text = ''
      ZESTTY_PLUGIN_URL="file:${zellijPluginDir}/zestty.wasm"
      ZESTTY_DEFAULT_LAYOUT="compact"
    '';
  };
}
