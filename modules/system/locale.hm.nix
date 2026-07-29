let
  localePolicy = import ./locale-policy.nix;
in {
  home.sessionVariables = localePolicy.homeSessionVariables;
}
