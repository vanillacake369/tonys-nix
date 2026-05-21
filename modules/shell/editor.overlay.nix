# Pin neovim to 0.11.x — prevents breaking changes from unstable nixpkgs updates.
_final: prev: {
  neovim = prev.neovim.overrideAttrs (_old: rec {
    version = "0.11.6";
    src = prev.fetchFromGitHub {
      owner = "neovim";
      repo = "neovim";
      tag = "v${version}";
      hash = "sha256-aX2IW9BCXL+GYymSRe12PbKyIi/H9LDzEp5gVPY81Ok=";
    };
  });
}
