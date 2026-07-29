{
  config,
  lib,
  isDarwin,
  ...
}: let
  fontPolicy = import ./font-policy.nix;
  luaString = builtins.toJSON;
  jetendardFontDirs =
    [
      "${config.home.homeDirectory}/${fontPolicy.jetendard.userFontDir}"
    ]
    ++ lib.optionals isDarwin [
      "${config.home.homeDirectory}/${fontPolicy.jetendard.darwinFontDir}"
    ];
  jetendardFontDirsLua = lib.concatMapStringsSep "\n" (dir: "    ${luaString dir},") jetendardFontDirs;
  weztermConfig =
    builtins.replaceStrings
    [
      "    -- @JETENDARD_FONT_DIRS@"
      "    -- @JETENDARD_FAMILY@"
    ]
    [
      jetendardFontDirsLua
      "    ${luaString fontPolicy.jetendard.family},"
    ]
    (builtins.readFile ../../dotfiles/wezterm/wezterm.lua);
in {
  # NOTE:
  # WezTerm 설정은 font package, Home Manager font link, dotfile template이
  # 합성되는 지점이다. apps.hm.nix에 두면 “패키지 설치”와 “runtime config
  # 생성”이 섞이므로 이 모듈이 terminal emulator 설정만 소유한다.
  home.file.".wezterm.lua".text = weztermConfig;
}
