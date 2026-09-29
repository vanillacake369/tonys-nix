{lib}: let
  fishHm = builtins.readFile ../../modules/shell/fish.hm.nix;

  assert' = name: cond:
    if cond
    then {
      inherit name;
      pass = true;
    }
    else throw "FAIL: ${name}";
in {
  results = [
    (assert' "GIVEN Nix Fish on Darwin WHEN Homebrew owns CLIs THEN Brew completion paths are discovered" (
      lib.hasInfix "lib.optionalString isDarwin" fishHm
      && lib.hasInfix "brew --prefix" fishHm
      && lib.hasInfix "share/fish/vendor_completions.d" fishHm
    ))
    (assert' "GIVEN Brew container CLIs WHEN formula completions are available THEN Podman and Docker paths are considered" (
      lib.hasInfix "for formula in podman docker" fishHm
      && lib.hasInfix "brew --prefix $formula" fishHm
    ))
    (assert' "GIVEN user Fish completions WHEN Brew completions are discovered THEN user completions keep precedence" (
      lib.hasInfix "set -a fish_complete_path $completion_dir" fishHm
      && !lib.hasInfix "set -p fish_complete_path $completion_dir" fishHm
    ))
  ];
}
