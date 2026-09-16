{
  config,
  isDarwin,
  lib,
  pkgs,
  ...
}: let
  zellijPluginDir = "${config.home.homeDirectory}/.config/zellij/plugins";
  zellijConfig = import ../../lib/mk-zellij-config.nix {
    inherit isDarwin;
    fishPath = "${pkgs.fish}/bin/fish";
    pluginDir = zellijPluginDir;
  };
in {
  home.packages = [
    pkgs.zellij-nav
    pkgs.zestty
  ];

  home.activation.zellijNavSwitcherPermissions = lib.hm.dag.entryAfter ["linkGeneration"] ''
    cache_dir="$(${pkgs.zellij}/bin/zellij setup --check 2>/dev/null | ${pkgs.gawk}/bin/awk -F': ' '/\[CACHE DIR\]/ { gsub(/"/, "", $2); print $2; exit }')"
    if [ -n "$cache_dir" ]; then
      permission_file="$cache_dir/permissions.kdl"
      plugin_path="${zellijPluginDir}/zellij-nav-switcher.wasm"
      plugin_url="file:${zellijPluginDir}/zellij-nav-switcher.wasm"
      mkdir -p "$cache_dir"
      tmp_file="$(mktemp "$cache_dir/.permissions.XXXXXX")"
      if [ -f "$permission_file" ]; then
        ${pkgs.gawk}/bin/awk -v path_key="$plugin_path" -v url_key="$plugin_url" '
          $0 == "\"" path_key "\" {" { skip = 1; next }
          $0 == "\"" url_key "\" {" { skip = 1; next }
          skip == 1 {
            if ($0 ~ /^[[:space:]]*}/) { skip = 0 }
            next
          }
          { print }
        ' "$permission_file" > "$tmp_file"
      fi
      {
        cat "$tmp_file"
        printf '"%s" {\n' "$plugin_path"
        printf '    ChangeApplicationState\n'
        printf '    ReadCliPipes\n'
        printf '}\n'
        printf '"%s" {\n' "$plugin_url"
        printf '    ChangeApplicationState\n'
        printf '    ReadCliPipes\n'
        printf '}\n'
      } > "$tmp_file.next"
      mv "$tmp_file.next" "$permission_file"
      rm -f "$tmp_file"
    fi
  '';

  # NOTE:
  # zellij UI, helper scripts, wasm plugins, zestty bootstrap은 한 런타임 경계다.
  # 파일만 잘게 찢으면 activation 그래프는 얕아지지 않고 추적만 어려워진다.
  # 그래서 이 파일이 Home Manager entrypoint이자 terminal multiplexer bundle을
  # 배치한다. package/fetch 정의는 zellij overlay가 소유한다.
  home.file = {
    ".config/zellij/config.kdl".text = zellijConfig;
    ".config/zellij/scripts/zellij-pane-picker" = {
      source = "${pkgs.zellij-nav}/bin/zellij-nav";
      executable = true;
    };
    ".config/zellij/scripts/zellij-context-toggle" = {
      source = "${pkgs.zellij-nav}/bin/zellij-nav";
      executable = true;
    };
    ".config/zellij/scripts/zellij-nav" = {
      source = "${pkgs.zellij-nav}/bin/zellij-nav";
      executable = true;
    };
    ".config/zellij/scripts/zellij-nav-sidecar" = {
      source = "${pkgs.zellij-nav}/bin/zellij-nav";
      executable = true;
    };
    ".config/zellij/scripts/zellij-nav-plugin-switch" = {
      source = "${pkgs.zellij-nav}/bin/zellij-nav";
      executable = true;
    };
    ".config/zellij/plugins/zellij-nav-switcher.wasm".source = "${pkgs.zellij-nav-switcher}/share/zellij/plugins/zellij-nav-switcher.wasm";
    ".config/zellij/plugins/room.wasm".source = pkgs.zellij-room-wasm;
    ".config/zellij/plugins/zellij-forgot.wasm".source = pkgs.zellij-forgot-wasm;
    ".config/zellij/plugins/zestty.wasm".source = pkgs.zellij-zestty-wasm;
    ".config/zestty/config".text = ''
      ZESTTY_PLUGIN_URL="file:${zellijPluginDir}/zestty.wasm"
      ZESTTY_DEFAULT_LAYOUT="compact"
    '';
  };
}
