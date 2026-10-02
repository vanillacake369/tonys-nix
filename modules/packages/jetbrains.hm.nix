# JetBrains IDE integration: packages + keymap linking (all platforms)
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
  ideNames = [
    "IntelliJIdea"
    "GoLand"
    "DataGrip"
    "WebStorm"
    "PhpStorm"
    "PyCharm"
    "RubyMine"
    "CLion"
    "Rider"
    "AndroidStudio"
  ];
  ideGlob = lib.concatStringsSep "," ideNames;
in {
  home.packages =
    lib.optionals (isLinux && !isWsl) (with pkgs; [
      jetbrains.idea
      jetbrains.goland
      jetbrains.datagrip
    ])
    ++ lib.optionals isDarwin (with pkgs; [
      jetbrains.datagrip
    ]);

  home.file = lib.mkIf isDarwin {
    ".ideavimrc".source = ../../dotfiles/jetbrain/ideavim/.ideavimrc;
  };

  # NOTE:
  # JetBrains settings 디렉터리 이름은 IDE family contract에 가깝고 개인
  # identity가 아니다. userProfile에는 Windows home 같은 host-specific
  # 경로만 남기고, IDE 목록과 keymap link 정책은 이 integration이 소유한다.
  home.activation.linkJetBrainsSettings = lib.mkIf (isDarwin || isWsl) (let
    keymapFile =
      if isDarwin
      then "Mac.xml"
      else "Windows.xml";
    jetbrainsHome =
      if isDarwin
      then "${config.home.homeDirectory}/Library/Application Support/JetBrains"
      else "${userProfile.windowsHome}/AppData/Roaming/JetBrains";
    sourceKeymap =
      if isDarwin
      then "${../../dotfiles/jetbrain/keymap/Mac.xml}"
      else "${../../dotfiles/jetbrain/keymap/Windows.xml}";
    sourceIdeaVim = "${../../dotfiles/jetbrain/ideavim/.ideavimrc}";
  in
    lib.hm.dag.entryAfter ["writeBoundary"] ''
      SOURCE_KEYMAP="${sourceKeymap}"
      SOURCE_IDEAVIM="${sourceIdeaVim}"
      JETBRAINS_HOME="${jetbrainsHome}"

      link_managed_file() {
        local source="$1" destination="$2"
        if [[ -L "$destination" || ! -e "$destination" ]]; then
          ln -sfn "$source" "$destination"
        else
          echo "Skipping existing JetBrains setting: $destination" >&2
        fi
      }

      if [[ "${
        if isWsl
        then "true"
        else "false"
      }" == true && -f "$SOURCE_IDEAVIM" ]]; then
        link_managed_file "$SOURCE_IDEAVIM" "${userProfile.windowsHome}/.ideavimrc"
      fi

      if [[ -d "$JETBRAINS_HOME" && -f "$SOURCE_KEYMAP" ]]; then
        for ide_dir in "$JETBRAINS_HOME"/{${ideGlob}}*; do
          if [[ -d "$ide_dir" ]]; then
            KEYMAP_DIR="$ide_dir/keymaps"
            mkdir -p "$KEYMAP_DIR"
            link_managed_file "$SOURCE_KEYMAP" "$KEYMAP_DIR/${keymapFile}"
          fi
        done
      fi
    '');
}
