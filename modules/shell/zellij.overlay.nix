_final: prev: let
  zellijNavRoot = ../../dotfiles/zellij/nav;
  zellijNavSwitcherRoot = ../../dotfiles/zellij/nav/wasm/switcher;
  cleanZellijSource = src: excludePrefixes:
    prev.lib.cleanSourceWith {
      inherit src;
      filter = path: _type: let
        rel = prev.lib.removePrefix "${toString src}/" (toString path);
      in
        !(builtins.any (prefix: prev.lib.hasPrefix prefix rel) excludePrefixes);
    };
  zellijWasmToolchain = prev.rust-bin.stable.latest.default.override {
    targets = ["wasm32-wasip1"];
  };
  zellijWasmRustPlatform = prev.makeRustPlatform {
    cargo = zellijWasmToolchain;
    rustc = zellijWasmToolchain;
  };
in {
  zellij-nav = prev.rustPlatform.buildRustPackage {
    pname = "zellij-nav";
    version = "0.1.0";
    src = cleanZellijSource zellijNavRoot ["target/" "wasm/"];
    cargoLock.lockFile = ../../dotfiles/zellij/nav/Cargo.lock;
  };

  zellij-nav-switcher = zellijWasmRustPlatform.buildRustPackage {
    pname = "zellij-nav-switcher";
    version = "0.1.0";
    src = cleanZellijSource zellijNavSwitcherRoot ["target/"];
    cargoLock.lockFile = ../../dotfiles/zellij/nav/wasm/switcher/Cargo.lock;
    nativeBuildInputs = [prev.pkg-config];
    buildInputs = [prev.openssl];
    OPENSSL_INCLUDE_DIR = "${prev.openssl.dev}/include";
    OPENSSL_LIB_DIR = "${prev.openssl.out}/lib";
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

  zestty = prev.stdenvNoCC.mkDerivation {
    pname = "zestty";
    version = "0.2.1";
    src = prev.fetchurl {
      url = "https://github.com/aidantlynch00/zestty/releases/download/v0.2.1/zestty";
      hash = "sha256-vGQ8vvzMX9TnTect7P5s2r5iAQqHk+Mqd40Sy3ady7o=";
    };
    dontUnpack = true;
    installPhase = ''
      install -Dm755 "$src" "$out/bin/zestty"
    '';
  };

  zellij-room-wasm = prev.fetchurl {
    url = "https://github.com/rvcas/room/releases/download/v1.2.1/room.wasm";
    hash = "sha256-kLSDpAt2JGj7dYYhYFh6BfvtzVwTrcs+0jHwG/nActE=";
  };

  zellij-forgot-wasm = prev.fetchurl {
    url = "https://github.com/karimould/zellij-forgot/releases/download/0.4.2/zellij_forgot.wasm";
    hash = "sha256-MRlBRVGdvcEoaFtFb5cDdDePoZ/J2nQvvkoyG6zkSds=";
  };

  zellij-zestty-wasm = prev.fetchurl {
    url = "https://github.com/aidantlynch00/zestty/releases/download/v0.2.1/zestty.wasm";
    hash = "sha256-AOBm2BUOuGtw6LwvD1acUEFqiKevKaqZ4vJ015yVOf8=";
  };
}
