{
  lib,
  pkgs,
  isDarwin,
  ...
}: let
  fontPolicy = import ./font-policy.nix;
  jetendardFonts = "${pkgs.jetendard}/${fontPolicy.jetendard.packageFontDir}";
in {
  # Font SSoT: Home Manager owns font links without adding font packages to ~/.nix-profile.
  fonts.fontconfig.enable = true;

  home.file =
    {
      "${fontPolicy.jetendard.userFontDir}".source = jetendardFonts;
    }
    // lib.optionalAttrs isDarwin {
      "${fontPolicy.jetendard.darwinFontDir}".source = jetendardFonts;
    };
}
