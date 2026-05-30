{
  lib,
  isLinux,
  isDarwin,
  isNixOs,
  userProfile,
  ...
}: let
  keymaps = import ./modules/keymap/pipeline.nix {inherit lib userProfile;};
  zellijConfig = import ./lib/mk-zellij-config.nix {inherit isDarwin;};
  domainModules = import ./lib/discover-modules.nix {inherit lib;} ./modules;
in {
  programs.home-manager.enable = true;
  targets.genericLinux.enable = isLinux;

  home.file =
    {
      ".config/nix".source = ./dotfiles/nix;
      ".config/nixpkgs".source = ./dotfiles/nixpkgs;
      ".screenrc".source = ./dotfiles/screen/.screenrc;
      ".config/zellij/config.kdl".text = zellijConfig;
      ".config/hypr/hyprland.conf".source = ./dotfiles/hypr/hyprland.conf;
    }
    // lib.optionalAttrs isDarwin {
      ".config/karabiner/karabiner.json" = {
        text = keymaps.karabinerJson;
        force = true;
      };
      ".config/aerospace/aerospace.toml" = {
        text = keymaps.aerospaceToml;
        force = true;
      };
    };

  imports =
    domainModules.homeManager
    ++ lib.optionals isNixOs [./modules/desktop/hyprland.nix]
    ++ lib.optionals (isLinux && !isNixOs) [./modules/system/wsl.nix];
}
