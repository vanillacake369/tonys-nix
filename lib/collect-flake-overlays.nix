{
  lib,
  llm-agents,
  nixpkgs-neovim,
  rust-overlay,
}: modulesDir: let
  # NOTE:
  #   overlay 순서는 package API의 일부다. 로컬 module overlay는 파일
  #   컨벤션으로 수집하고, flake-level 외부 overlay는 뒤에 명시적으로 붙인다.
  #   그래야 provider input과 cross-cutting pin이 로컬 module 파일인 척하지
  #   않으면서도 flake.nix에 흩어지지 않는다.
  moduleOverlays = (import ./collect-overlays.nix {inherit lib;}) modulesDir;
  rustToolchainOverlay = import rust-overlay;
  pinnedNeovimOverlay = _final: prev: {
    neovim-unwrapped =
      nixpkgs-neovim.legacyPackages.${prev.stdenv.hostPlatform.system}.neovim-unwrapped;
  };
in
  moduleOverlays
  ++ [
    llm-agents.overlays.default
    rustToolchainOverlay
    pinnedNeovimOverlay
  ]
