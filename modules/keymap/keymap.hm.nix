{
  config,
  lib,
  pkgs,
  isDarwin,
  ...
}: let
  spec = builtins.fromTOML (builtins.readFile ./binds.toml);

  karabinerJson = import ./to-karabiner.nix {
    inherit lib spec;
  };

  aerospaceToml = import ./to-aerospace.nix {
    inherit lib spec;
  };

  karabinerConfig = pkgs.writeText "karabiner.json" karabinerJson;
in {
  home.file = lib.optionalAttrs isDarwin {
    ".config/aerospace/aerospace.toml" = {
      text = aerospaceToml;
      force = true;
    };
  };

  # Karabiner does not reliably cooperate with Home Manager's symlink model,
  # so copy the generated file only when its contents changed.
  home.activation.syncKarabinerConfig = lib.mkIf isDarwin (
    lib.hm.dag.entryAfter ["linkGeneration"] ''
      target="${config.home.homeDirectory}/.config/karabiner/karabiner.json"
      legacy_marker="${config.home.homeDirectory}/.local/state/tonys-nix/karabiner-json.sha256"

      rm -f "$legacy_marker"

      if [[ -f "$target" ]] && cmp -s "${karabinerConfig}" "$target"; then
        echo "[→] Karabiner config sync skipped - content unchanged"
      else
        mkdir -p "$(dirname "$target")"
        rm -f "$target"
        install -m 0644 "${karabinerConfig}" "$target"
        echo "[✓] Karabiner config synced"
      fi
    ''
  );
}
