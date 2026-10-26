{lib}: let
  utilsHm = builtins.readFile ../../modules/shell/utils.hm.nix;
  gitHm = builtins.readFile ../../modules/shell/git.hm.nix;
  zellijHm = builtins.readFile ../../modules/shell/zellij.hm.nix;
  languageHm = builtins.readFile ../../modules/language/language.hm.nix;

  assert' = name: cond:
    if cond
    then {
      inherit name;
      pass = true;
    }
    else throw "FAIL: ${name}";
in {
  results = [
    (assert' "shell boundaries: monitoring is a utility concern" (
      !(builtins.pathExists ../../modules/shell/monitor.hm.nix)
      && builtins.all (package: lib.hasInfix package utilsHm) [
        "htop"
        "btop"
        "dust"
        "ncdu"
        "smartmontools"
        "strace"
      ]
    ))
    (assert' "shell boundaries: Git and Zellij executables have one owner" (
      builtins.all (package: lib.hasInfix package gitHm && !(lib.hasInfix package utilsHm)) [
        "lazygit"
        "delta"
        "git-filter-repo"
        "git-crypt"
        "gh"
      ]
      && lib.hasInfix "pkgs.zellij" zellijHm
      && !(lib.hasInfix "zellij" utilsHm)
    ))
    (assert' "docker tooling: Nix provides a Dockerfile LSP with lint support" (
      lib.hasInfix "pkgs.dockerfile-language-server" languageHm
      && lib.hasInfix "pkgs.hadolint" languageHm
      && lib.hasInfix "pkgs.docker-compose-language-service" languageHm
    ))
  ];
}
