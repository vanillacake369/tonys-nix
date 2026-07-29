_final: prev: {
  # NOTE:
  # Jetendard는 Home Manager font link와 WezTerm family injection이 같이
  # 참조하는 repository-local font package다. hash를 고정해 폰트 렌더링과
  # fallback 순서가 nixpkgs bump와 무관하게 유지되도록 한다.
  jetendard = prev.stdenvNoCC.mkDerivation {
    pname = "jetendard";
    version = "0.1.0";

    src = prev.fetchurl {
      url = "https://github.com/kuskhan/jetendard/releases/download/v0.1.0/Jetendard-TTF.zip";
      hash = "sha256-OZq0FolcAd3B1D21CdeqfO3krSCfWXroY5xtAZTCsTM=";
    };

    nativeBuildInputs = [prev.unzip];

    unpackPhase = ''
      unzip -q "$src"
    '';

    installPhase = ''
      runHook preInstall
      install -Dm644 ttf/*.ttf -t "$out/share/fonts/truetype/Jetendard"
      runHook postInstall
    '';
  };
}
