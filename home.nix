{
  lib,
  isLinux,
  isDarwin,
  isNixOs,
  userProfile,
  ...
}: let
  keymaps = import ./lib/dotfiles/keymaps.nix {inherit lib userProfile;};
  zellijConfig = import ./lib/dotfiles/zellij.nix {inherit lib isDarwin;};
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
    [
      ./modules/agents
      ./modules/apps.nix
      ./modules/packages/jetbrains.nix
      ./modules/language.nix
      ./modules/shell
      ./modules/shell-infra.nix
      ./modules/shell-utils.nix
      ./modules/shell-network.nix
      ./modules/shell-monitor.nix
    ]
    ++ lib.optionals isNixOs [./modules/settings-hyprland.nix]
    ++ lib.optionals (isLinux && !isNixOs) [./modules/settings-wsl.nix];
}
