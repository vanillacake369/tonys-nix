let
  localePolicy = import ../lib/locale-policy.nix;
in {
  home.sessionVariables = localePolicy.homeSessionVariables;
}
