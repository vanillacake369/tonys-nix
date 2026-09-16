{lib}: let
  fontPolicy = import ../../modules/packages/font-policy.nix;
  localePolicy = import ../../modules/system/locale-policy.nix;
  appsHm = builtins.readFile ../../modules/packages/apps.hm.nix;
  nixConfigHm = builtins.readFile ../../modules/shell/nix-config.hm.nix;
  localeHm = builtins.readFile ../../modules/system/locale.hm.nix;
  weztermHm = builtins.readFile ../../modules/packages/wezterm.hm.nix;
  weztermTemplate = builtins.readFile ../../dotfiles/wezterm/wezterm.lua;

  assert' = name: cond:
    if cond
    then {
      inherit name;
      pass = true;
    }
    else throw "FAIL: ${name}";
in {
  results = [
    (assert' "GIVEN locale policy WHEN home session variables are rendered THEN LC_ALL is not persistent" (!(localePolicy.homeSessionVariables ? LC_ALL)))
    (assert' "GIVEN locale policy WHEN default language is read THEN English UTF-8 is used" (localePolicy.homeSessionVariables.LANG == "en_US.UTF-8"))
    (assert' "GIVEN locale policy WHEN regional categories are read THEN Korean categories are explicit" (
      localePolicy.categoryLocales.LC_TIME
      == "ko_KR.UTF-8"
      && localePolicy.categoryLocales.LC_MONETARY == "ko_KR.UTF-8"
      && localePolicy.categoryLocales.LC_NUMERIC == "ko_KR.UTF-8"
    ))
    (assert' "GIVEN locale policy WHEN command-facing categories are read THEN command output stays English" (
      localePolicy.categoryLocales.LC_COLLATE
      == "en_US.UTF-8"
      && localePolicy.categoryLocales.LC_CTYPE == "en_US.UTF-8"
      && localePolicy.categoryLocales.LC_MESSAGES == "en_US.UTF-8"
    ))
    (assert' "GIVEN locale modules WHEN home-manager policy is wired THEN system module owns locale policy" (
      lib.hasInfix "locale-policy.nix" localeHm
      && !(lib.hasInfix "locale-policy.nix" nixConfigHm)
    ))
    (assert' "GIVEN font policy WHEN Jetendard is read THEN family is centralized" (fontPolicy.jetendard.family == "Jetendard"))
    (assert' "GIVEN WezTerm template WHEN font dirs are managed THEN template does not hard-code generated dirs" (
      !(lib.hasInfix ".local/share/fonts/Jetendard" weztermTemplate)
      && !(lib.hasInfix "Library/Fonts/Jetendard" weztermTemplate)
      && !(lib.hasInfix ".nix-profile/share/fonts" weztermTemplate)
    ))
    (assert' "GIVEN app modules WHEN WezTerm config is rendered THEN font policy owns Jetendard config" (
      !(lib.hasInfix "font-policy.nix" appsHm)
      && lib.hasInfix "font-policy.nix" weztermHm
      && lib.hasInfix ".wezterm.lua\".text = weztermConfig" weztermHm
      && lib.hasInfix "fontPolicy.jetendard.family}," weztermHm
      && lib.hasInfix "-- @JETENDARD_FONT_DIRS@" weztermTemplate
      && lib.hasInfix "-- @JETENDARD_FAMILY@" weztermTemplate
    ))
  ];
}
