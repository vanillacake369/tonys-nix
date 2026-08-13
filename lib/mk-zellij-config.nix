# Generates platform-specific zellij config from a single base.
# Differences: copy_command, Ctrl unbinds (darwin only), kitty protocol (darwin only),
# and runtime paths.
{
  isDarwin,
  fishPath ? "fish",
  pluginDir ? "~/.config/zellij/plugins",
}: let
  base = builtins.readFile ../dotfiles/zellij/config.kdl.base;
  metadataRoot = ../dotfiles/zellij;

  collectPluginMetadata = path: let
    entries = builtins.readDir path;
    names = builtins.attrNames entries;
    files =
      builtins.filter
      (name: entries.${name} == "regular" && name == "zellij-plugin.toml")
      names;
    dirs =
      builtins.filter
      (
        name:
          entries.${name}
          == "directory"
          && !(builtins.elem name ["target" ".git" ".direnv"])
      )
      names;
  in
    (map (name: path + "/${name}") files)
    ++ builtins.concatLists (map (name: collectPluginMetadata (path + "/${name}")) dirs);

  escapeKdlString = value:
    builtins.replaceStrings ["\\" "\""] ["\\\\" "\\\""] value;

  pluginMetadata =
    map
    (file: builtins.fromTOML (builtins.readFile file))
    (collectPluginMetadata metadataRoot);

  forgotPluginEntries = builtins.concatStringsSep "\n" (
    map
    (entry: "                \"${escapeKdlString entry.label}\" \"${escapeKdlString entry.keys}\"")
    (builtins.concatLists (map (metadata: metadata.forgot or []) pluginMetadata))
  );

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
    ''default_shell "fish"''
    "                # @ZELLIJ_FORGOT_PLUGIN_ENTRIES@"
    "file:~/.config/zellij/plugins"
  ]
  [
    copyCommand
    kittyLine
    ctrlUnbinds
    ''default_shell "${fishPath}"''
    forgotPluginEntries
    "file:${pluginDir}"
  ]
  base
