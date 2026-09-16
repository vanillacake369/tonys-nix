{
  lib,
  llm-agents,
  nixpkgs-neovim,
  rust-overlay,
}: modulesDir: let
  # NOTE:
  #   overlay 순서는 package API의 일부다. toolchain provider overlay는 로컬
  #   module overlay보다 먼저 적용해 module package가 그 API를 쓸 수 있게 한다.
  #   cross-cutting runtime pin은 마지막에 둬 최종 runtime core를 결정한다.
  moduleOverlays =
    import ./collect-overlays.nix {
      inherit lib;
      overlayArgs = {inherit llm-agents;};
    }
    modulesDir;
  rustToolchainOverlay = import rust-overlay;
  pinnedNeovimOverlay = _final: prev: {
    neovim-unwrapped =
      nixpkgs-neovim.legacyPackages.${prev.stdenv.hostPlatform.system}.neovim-unwrapped;
  };
in
  [rustToolchainOverlay]
  ++ moduleOverlays
  ++ [
    pinnedNeovimOverlay
  ]
