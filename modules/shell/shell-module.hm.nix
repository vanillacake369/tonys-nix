{
  lib,
  isDarwin,
  ...
}: let
  zellijConfig = import ../../lib/mk-zellij-config.nix {inherit isDarwin;};
in {
  imports = [
    ./fish.nix
    ./git.nix
    ./editor.nix
    ./fzf.nix
    ./direnv.nix
    ./yazi.nix
    ./infra.nix
    ./monitor.nix
    ./utils.nix
  ];

  home.sessionVariables = {
    NIXPKGS_ALLOW_UNFREE = "1";
  };

  home.file =
    {
      ".config/nix".source = ../../dotfiles/nix;
      ".config/nixpkgs".source = ../../dotfiles/nixpkgs;
      ".screenrc".source = ../../dotfiles/screen/.screenrc;
      ".config/zellij/config.kdl".text = zellijConfig;
    };
}
