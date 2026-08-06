{
  config,
  isDarwin,
  lib,
  pkgs,
  ...
}: let
  zellijPluginDir = "${config.home.homeDirectory}/.config/zellij/plugins";
  zellijNavRoot = ../../dotfiles/zellij/nav;
  zellijNavSwitcherRoot = ../../dotfiles/zellij/nav/wasm/switcher;
  cleanZellijSource = src: excludePrefixes:
    lib.cleanSourceWith {
      inherit src;
      filter = path: _type: let
        rel = lib.removePrefix "${toString src}/" (toString path);
      in
        !(builtins.any (prefix: lib.hasPrefix prefix rel) excludePrefixes);
    };
  zellijConfig = import ../../lib/mk-zellij-config.nix {
    inherit isDarwin;
    fishPath = "${pkgs.fish}/bin/fish";
    pluginDir = zellijPluginDir;
  };
  zellijNav = pkgs.rustPlatform.buildRustPackage {
    pname = "zellij-nav";
    version = "0.1.0";
    src = cleanZellijSource zellijNavRoot ["target/" "wasm/"];
    cargoLock.lockFile = ../../dotfiles/zellij/nav/Cargo.lock;
  };
  zellijWasmToolchain = pkgs.rust-bin.stable.latest.default.override {
    targets = ["wasm32-wasip1"];
  };
  zellijWasmRustPlatform = pkgs.makeRustPlatform {
    cargo = zellijWasmToolchain;
    rustc = zellijWasmToolchain;
  };
  zellijNavSwitcher = zellijWasmRustPlatform.buildRustPackage {
    pname = "zellij-nav-switcher";
    version = "0.1.0";
    src = cleanZellijSource zellijNavSwitcherRoot ["target/"];
    cargoLock.lockFile = ../../dotfiles/zellij/nav/wasm/switcher/Cargo.lock;
    nativeBuildInputs = [pkgs.pkg-config];
    buildInputs = [pkgs.openssl];
    OPENSSL_INCLUDE_DIR = "${pkgs.openssl.dev}/include";
    OPENSSL_LIB_DIR = "${pkgs.openssl.out}/lib";
    doCheck = false;
    buildPhase = ''
      runHook preBuild
      cargo build --offline --release --target wasm32-wasip1
      runHook postBuild
    '';
    installPhase = ''
      runHook preInstall
      install -Dm644 target/wasm32-wasip1/release/zellij_nav_switcher.wasm "$out/share/zellij/plugins/zellij-nav-switcher.wasm"
      runHook postInstall
    '';
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

  home.activation.zellijNavSwitcherPermissions = lib.hm.dag.entryAfter ["linkGeneration"] ''
    cache_dir="$(${pkgs.zellij}/bin/zellij setup --check 2>/dev/null | ${pkgs.gawk}/bin/awk -F': ' '/\[CACHE DIR\]/ { gsub(/"/, "", $2); print $2; exit }')"
    if [ -n "$cache_dir" ]; then
      permission_file="$cache_dir/permissions.kdl"
      plugin_path="${zellijPluginDir}/zellij-nav-switcher.wasm"
      plugin_url="file:${zellijPluginDir}/zellij-nav-switcher.wasm"
      mkdir -p "$cache_dir"
      tmp_file="$(mktemp "$cache_dir/.permissions.XXXXXX")"
      if [ -f "$permission_file" ]; then
        ${pkgs.gawk}/bin/awk -v path_key="$plugin_path" -v url_key="$plugin_url" '
          $0 == "\"" path_key "\" {" { skip = 1; next }
          $0 == "\"" url_key "\" {" { skip = 1; next }
          skip == 1 {
            if ($0 ~ /^[[:space:]]*}/) { skip = 0 }
            next
          }
          { print }
        ' "$permission_file" > "$tmp_file"
      fi
      {
        cat "$tmp_file"
        printf '"%s" {\n' "$plugin_path"
        printf '    ChangeApplicationState\n'
        printf '    ReadCliPipes\n'
        printf '}\n'
        printf '"%s" {\n' "$plugin_url"
        printf '    ChangeApplicationState\n'
        printf '    ReadCliPipes\n'
        printf '}\n'
      } > "$tmp_file.next"
      mv "$tmp_file.next" "$permission_file"
      rm -f "$tmp_file"
    fi
  '';

  # NOTE:
  # zellij UI, helper scripts, wasm plugins, zestty bootstrap은 한 런타임 경계다.
  # 파일만 잘게 찢으면 activation 그래프는 얕아지지 않고 추적만 어려워진다.
  # 그래서 이 파일이 Home Manager entrypoint이자 terminal multiplexer bundle을
  # 직접 소유한다. 별도 shell entrypoint layer는 만들지 않는다.
  home.file = {
    ".config/zellij/config.kdl".text = zellijConfig;
    ".config/zellij/scripts/zellij-pane-picker" = {
      source = "${zellijNav}/bin/zellij-nav";
      executable = true;
    };
    ".config/zellij/scripts/zellij-context-toggle" = {
      source = "${zellijNav}/bin/zellij-nav";
      executable = true;
    };
    ".config/zellij/scripts/zellij-nav" = {
      source = "${zellijNav}/bin/zellij-nav";
      executable = true;
    };
    ".config/zellij/scripts/zellij-nav-sidecar" = {
      source = "${zellijNav}/bin/zellij-nav";
      executable = true;
    };
    ".config/zellij/scripts/zellij-nav-plugin-switch" = {
      source = "${zellijNav}/bin/zellij-nav";
      executable = true;
    };
    ".config/zellij/plugins/zellij-nav-switcher.wasm".source = "${zellijNavSwitcher}/share/zellij/plugins/zellij-nav-switcher.wasm";
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
