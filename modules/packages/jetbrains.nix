# JetBrains IDE integration: packages + keymap linking (all platforms)
# SSoT: userProfile.jetbrains provides IDE list and bundle IDs.
{
  config,
  lib,
  pkgs,
  isDarwin,
  isLinux,
  isWsl,
  userProfile,
  ...
}: let
  ideGlob = lib.concatStringsSep "," userProfile.jetbrains.ides;
in {
  home.packages = lib.optionals (isLinux && !isWsl) (with pkgs; [
    jetbrains.idea
    jetbrains.goland
    jetbrains.datagrip
  ]);

  home.activation.linkJetBrainsKeymaps = let
    keymapFile =
      if isDarwin
      then "Mac.xml"
      else "Windows.xml";
    jetbrainsDir =
      if isDarwin
      then "${config.home.homeDirectory}/Library/Application Support/JetBrains"
      else "${userProfile.windowsHome}/AppData/Roaming/JetBrains";
    sourceKeymap = "${config.home.homeDirectory}/dev/tonys-nix/dotfiles/jetbrain/keymap/${keymapFile}";
  in
    lib.hm.dag.entryAfter ["writeBoundary"] ''
      SOURCE_KEYMAP="${sourceKeymap}"
      JETBRAINS_DIR="${jetbrainsDir}"

      if [[ -d "$JETBRAINS_DIR" && -f "$SOURCE_KEYMAP" ]]; then
        for ide_dir in "$JETBRAINS_DIR"/{${ideGlob}}*; do
          if [[ -d "$ide_dir" ]]; then
            KEYMAP_DIR="$ide_dir/keymaps"
            mkdir -p "$KEYMAP_DIR"
            rm -f "$KEYMAP_DIR/${keymapFile}"
            ln -sf "$SOURCE_KEYMAP" "$KEYMAP_DIR/${keymapFile}"
          fi
        done
      fi
    '';
}
