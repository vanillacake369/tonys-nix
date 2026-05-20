# Keymap generation pipeline: keybinds.nix → spec validation → karabiner.json + aerospace.toml
# Extracted from home.nix to keep it purely declarative.
{
  lib,
  userProfile,
}: let
  spec = import ../keymaps/spec.nix {inherit lib;};
  rawKeybinds = import ../keymaps/keybinds.nix {inherit userProfile;};
  keybinds = rawKeybinds // {keymaps = spec.validate rawKeybinds.keymaps;};
in {
  inherit keybinds;
  karabinerJson = import ../keymaps/to-karabiner.nix {inherit lib keybinds;};
  aerospaceToml = import ../keymaps/to-aerospace.nix {inherit lib keybinds;};
}
