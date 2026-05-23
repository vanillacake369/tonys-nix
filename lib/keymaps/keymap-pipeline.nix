# Keymap generation pipeline: keybinds → spec validation → karabiner.json + aerospace.toml
{
  lib,
  userProfile,
}: let
  spec = import ./keymap-validator.nix {inherit lib;};
  rawKeybinds = import ./keymap-binds.nix {inherit userProfile;};
  keybinds = rawKeybinds // {keymaps = spec.validate rawKeybinds.keymaps;};
in {
  inherit keybinds;
  karabinerJson = import ./keymap-to-karabiner.nix {inherit lib keybinds;};
  aerospaceToml = import ./keymap-to-aerospace.nix {inherit lib keybinds;};
}
