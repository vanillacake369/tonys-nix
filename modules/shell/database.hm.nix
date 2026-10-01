# Database connection forwarding from the encrypted repository source of truth.
{
  config,
  lib,
  pkgs,
  ...
}: let
  encryptedDatabase = ../../secrets/database.yaml;
in {
  home.activation.installDatabaseConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    database_dir="${config.xdg.configHome}/database"
    database_file="$database_dir/databases.toml"

    if [ "$(uname -s)" = "Darwin" ]; then
      default_age_key_file="$HOME/Library/Application Support/sops/age/keys.txt"
    else
      default_age_key_file="''${XDG_CONFIG_HOME:-$HOME/.config}/sops/age/keys.txt"
    fi

    if [ -z "''${SOPS_AGE_KEY_FILE:-}" ] && [ -f "$default_age_key_file" ]; then
      export SOPS_AGE_KEY_FILE="$default_age_key_file"
    fi

    umask 077
    set -o pipefail
    mkdir -p "$database_dir"
    chmod 700 "$database_dir"
    temporary_file="$(mktemp "$database_dir/.databases.toml.XXXXXX")"
    trap 'rm -f "$temporary_file"' EXIT

    if ! ${pkgs.sops}/bin/sops decrypt \
      --input-type yaml \
      --output-type yaml \
      ${encryptedDatabase} \
      | ${pkgs.yq-go}/bin/yq eval -p=yaml -o=toml '.' - >"$temporary_file"; then
      echo "database config: failed to decrypt or render encrypted source" >&2
      exit 1
    fi

    if [ ! -s "$temporary_file" ]; then
      echo "database config: refusing to install an empty file" >&2
      exit 1
    fi

    chmod 600 "$temporary_file"
    mv -f "$temporary_file" "$database_file"
    trap - EXIT
  '';
}
