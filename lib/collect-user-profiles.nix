{lib}: dir:
# NOTE:
#   user/*.nix가 profile registry다. 이 pipeline은 regular .nix 파일만
#   profile로 승격하고, 파일명을 public profile name으로 삼은 뒤, 각 파일을
#   한 번 import해서 attrset으로 접는다. 디렉터리, 생성물, editor backup은
#   의도적으로 무시한다.
lib.pipe (builtins.readDir dir) [
  (lib.filterAttrs (_: type: type == "regular"))
  builtins.attrNames
  (builtins.filter (lib.hasSuffix ".nix"))
  (map (name: {
    name = lib.removeSuffix ".nix" name;
    value = import (dir + "/${name}");
  }))
  builtins.listToAttrs
]
