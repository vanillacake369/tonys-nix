# Keymap generation pipeline: keybinds → spec validation → karabiner.json + aerospace.toml
{
  lib,
  userProfile,
}: let
  spec = import ./spec.nix {inherit lib;};
  rawKeybinds = import ./keybinds.nix {inherit userProfile;};
  keybinds = rawKeybinds // {keymaps = spec.validate rawKeybinds.keymaps;};
in {
  inherit keybinds;
  karabinerJson = import ./to-karabiner.nix {inherit lib keybinds;};
  aerospaceToml = import ./to-aerospace.nix {inherit lib keybinds;};
}
