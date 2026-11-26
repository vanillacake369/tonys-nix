{
  config,
  isDarwin,
  lib,
  pkgs,
  ...
}: let
  cfg = config.tonys.darwin.defaultOpeners;

  wezvimBundleId = "kr.tonys-nix.WezVim";
  wezvimAppName = "WezVim";
  wezvimAppPath = "${config.home.homeDirectory}/Applications/${wezvimAppName}.app";

  # Finder 기본 앱 등록은 확장자 whitelist만 다룬다.
  # 앞의 점과 대소문자를 정리한 뒤 duti 호출 목록으로 펼쳐 shell quoting을 한곳에 모은다.
  extensions = lib.unique (map (ext: lib.toLower (lib.removePrefix "." ext)) cfg.extensions);
  dutiLines =
    lib.concatMapStringsSep "\n" (ext: ''
      if ${pkgs.duti}/bin/duti -s ${lib.escapeShellArg wezvimBundleId} ${lib.escapeShellArg ".${ext}"} all; then
        echo "[✓] Default opener set: .${ext} -> ${wezvimAppName}"
      else
        echo "[!] Default opener skipped: .${ext} -> ${wezvimAppName}" >&2
      fi
    '')
    extensions;

  ## AppleScript 앱은 빈 PATH로 실행될 수 있다.
  ## wrapper에서 Nix profile, Homebrew, system path 를 복원한 뒤 WezTerm 안에서 nvim을 연다.
  wezvimOpen = pkgs.writeShellScriptBin "wezvim-open" ''
    set -eu

    path_parts=(
      "/etc/profiles/per-user/$(id -un)/bin"
      "${config.home.homeDirectory}/.nix-profile/bin"
      "/opt/homebrew/bin"
      "/usr/local/bin"
      "/usr/bin"
      "/bin"
    )
    PATH="$(IFS=:; echo "''${path_parts[*]}")"
    export PATH

    WEZTERM="$(command -v wezterm || command -v wezterm-gui || true)"
    NVIM="$(command -v nvim || true)"

    if [[ -z "$WEZTERM" || -z "$NVIM" ]]; then
      echo "wezterm or nvim was not found." >&2
      exit 1
    fi

    exec "$WEZTERM" start -- "$NVIM" "$@"
  '';

  ## Finder는 script 파일이 아니라 앱 번들을 기본 opener로 기대한다.
  ## AppleScript 앱은 Finder의 open event를 받아 wrapper로 넘기고, 호출자는 바로 반환한다.
  wezvimAppleScriptText = ''
    on run
      do shell script ${builtins.toJSON "${lib.escapeShellArg "${wezvimOpen}/bin/wezvim-open"} >/dev/null 2>&1 &"}
    end run

    on open input
      set shellCommand to ${builtins.toJSON (lib.escapeShellArg "${wezvimOpen}/bin/wezvim-open")}
      repeat with fileItem in input
        set shellCommand to shellCommand & " " & quoted form of POSIX path of fileItem
      end repeat
      do shell script shellCommand & " >/dev/null 2>&1 &"
    end open
  '';

  wezvimAppleScript = pkgs.writeText "wezvim.applescript" wezvimAppleScriptText;
in {
  ## 이 모듈은 개인용 WezVim opener만 소유한다.
  ## 다른 앱의 기본 연결은 macOS UI나 별도 모듈에 맡긴다.
  ## 여기서는 코드 파일 whitelist만 선언한다.
  options.tonys.darwin.defaultOpeners = {
    enable = lib.mkEnableOption "macOS default opener for code files" // {default = isDarwin;};

    extensions = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "bash"
        "c"
        "conf"
        "cpp"
        "css"
        "env"
        "fish"
        "go"
        "h"
        "html"
        "java"
        "js"
        "json"
        "jsx"
        "kt"
        "lua"
        "md"
        "nix"
        "py"
        "rb"
        "rs"
        "sh"
        "sql"
        "toml"
        "ts"
        "tsx"
        "txt"
        "vim"
        "xml"
        "yaml"
        "yml"
        "zsh"
      ];
      description = "File extensions to open with WezVim.";
    };
  };

  config = lib.mkIf (isDarwin && cfg.enable) {
    home.packages = [
      pkgs.duti
      wezvimOpen
    ];

    ## Home Manager symlink로 표현할 수 없는 macOS LaunchServices 상태를 activation에서 맞춘다.
    ## dry-run에서는 사용자 LaunchServices DB와 ~/Applications를 건드리지 않는다.
    home.activation.darwinDefaultOpeners = lib.hm.dag.entryAfter ["writeBoundary"] ''
      if [[ -v DRY_RUN ]]; then
        echo "[→] Darwin default opener sync skipped - dry run"
      else
        app_path=${lib.escapeShellArg wezvimAppPath}
        tmp_root="$(mktemp -d "${config.home.homeDirectory}/Applications/.WezVim.XXXXXX")"
        trap 'rm -rf "$tmp_root"' EXIT

        mkdir -p "$(dirname "$app_path")"
        tmp_app="$tmp_root/${wezvimAppName}.app"

        set_plist_string() {
          local key="$1"
          local value="$2"

          /usr/libexec/PlistBuddy -c "Set :$key $value" "$tmp_app/Contents/Info.plist" 2>/dev/null \
            || /usr/libexec/PlistBuddy -c "Add :$key string $value" "$tmp_app/Contents/Info.plist"
        }

        /usr/bin/osacompile -o "$tmp_app" ${lib.escapeShellArg wezvimAppleScript}
        set_plist_string CFBundleIdentifier ${lib.escapeShellArg wezvimBundleId}
        set_plist_string CFBundleName ${lib.escapeShellArg wezvimAppName}
        set_plist_string CFBundleDisplayName ${lib.escapeShellArg wezvimAppName}

        rm -rf "$app_path"
        mv "$tmp_app" "$app_path"
        core_services="/System/Library/Frameworks/CoreServices.framework"
        lsregister="$core_services/Frameworks/LaunchServices.framework/Support/lsregister"
        "$lsregister" -f "$app_path" 2>/dev/null || true

        ${dutiLines}
      fi
    '';
  };
}
