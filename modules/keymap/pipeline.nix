# Keymap generation pipeline: keybinds → karabiner.json + aerospace.toml
# binds.nix now contains the spec (detectType/validate) inline,
# so keymaps are already validated on import — no separate validator import needed.
{
  lib,
  userProfile,
}: let
  keybinds = import ./binds.nix {inherit lib userProfile;};
in {
  inherit keybinds;
  karabinerJson = import ./to-karabiner.nix {inherit lib keybinds;};
  aerospaceToml = import ./to-aerospace.nix {inherit lib keybinds;};
}
