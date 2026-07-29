# Time zone, internationalization, and input methods
{pkgs, ...}: let
  localePolicy = import ./locale-policy.nix;
in {
  # Set your time zone.
  time.timeZone = "Asia/Seoul";

  # Select internationalisation properties.
  i18n = {
    inherit (localePolicy) defaultLocale supportedLocales;
    extraLocaleSettings = localePolicy.categoryLocales;
    inputMethod = {
      enable = true;
      type = "ibus";
      ibus.engines = with pkgs.ibus-engines; [hangul];
    };
  };
}
