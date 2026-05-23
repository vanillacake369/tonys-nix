# Pin neovim to 0.11.x — prevents breaking changes from unstable nixpkgs updates.
# Pin neovim-unwrapped — programs.neovim (home-manager) wraps neovim-unwrapped,
# so the overlay must target neovim-unwrapped, not the wrapper.
_final: prev: {
  neovim-unwrapped = prev.neovim-unwrapped.overrideAttrs (_old: rec {
    version = "0.11.6";
    src = prev.fetchFromGitHub {
      owner = "neovim";
      repo = "neovim";
      tag = "v${version}";
      hash = "sha256-aX2IW9BCXL+GYymSRe12PbKyIi/H9LDzEp5gVPY81Ok=";
    };
  });
}
