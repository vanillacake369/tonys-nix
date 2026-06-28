{
  pkgs,
  tests,
  ...
}: {
  guard-tests = pkgs.runCommand "guard-tests" {} ''
    echo '${builtins.toJSON tests.summary}' > "$out"
  '';
}
