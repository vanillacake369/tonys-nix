# Pin terraform — state file format locks to version; accidental upgrade can corrupt state.
_final: prev: {
  terraform = prev.terraform.overrideAttrs (_old: rec {
    version = "1.15.2";
    src = prev.fetchFromGitHub {
      owner = "hashicorp";
      repo = "terraform";
      rev = "v${version}";
      hash = "sha256-jwmyZJHGfi2oO8FBebPKBQdXt61w02H6zbbqSXxMhMM=";
    };
    vendorHash = "sha256-Gv6V5aXqTuQoG1StbD/7Ln2QrLpMsW6fbUJUkyZMkvk=";
  });
}
