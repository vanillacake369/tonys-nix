{lib}: let
  detectType = m:
    if m ? to_if_alone || m ? to_if_held
    then "complex"
    else if m ? exec
    then "wm-exec"
    else if m ? shell
    then "shell"
    else if m ? to
    then "remap"
    else "unknown";

  validateEntry = i: m:
    assert m ? bind || builtins.throw "keymaps[${toString i}]: missing 'bind'";
    assert m ? tags && builtins.isList m.tags || builtins.throw "keymaps[${toString i}] (${m.bind}): missing or invalid 'tags'";
    assert detectType m != "unknown" || builtins.throw "keymaps[${toString i}] (${m.bind}): no action field (to/exec/shell/to_if_alone)"; m;

  validate = entries: lib.imap0 validateEntry entries;
in {
  inherit detectType validate;
}
