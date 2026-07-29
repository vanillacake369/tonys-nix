_: {
  home.sessionVariables = {
    NIXPKGS_ALLOW_UNFREE = "1";
  };

  home.file = {
    ".config/nix".source = ../../dotfiles/nix;
    ".config/nixpkgs".source = ../../dotfiles/nixpkgs;
    ".screenrc".source = ../../dotfiles/screen/.screenrc;
  };
}
