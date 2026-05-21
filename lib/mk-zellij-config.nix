# Generates platform-specific zellij config from a single base.
# Differences: copy_command, Ctrl unbinds (darwin only), kitty protocol (darwin only).
{isDarwin}: let
  base = builtins.readFile ../dotfiles/zellij/config.kdl.base;

  copyCommand =
    if isDarwin
    then ''copy_command "pbcopy"''
    else ''copy_command "xclip -selection clipboard"'';

  kittyLine =
    if isDarwin
    then "support_kitty_keyboard_protocol true"
    else "// support_kitty_keyboard_protocol false";

  ctrlUnbinds =
    if isDarwin
    then ''
      unbind "Ctrl /"
              unbind "Ctrl space"
              unbind "Ctrl s"''
    else "";
in
  builtins.replaceStrings
  [
    ''copy_command "pbcopy"''
    "support_kitty_keyboard_protocol true"
    ''      unbind "Ctrl /"
              unbind "Ctrl space"
              unbind "Ctrl s"''
  ]
  [
    copyCommand
    kittyLine
    ctrlUnbinds
  ]
  base
