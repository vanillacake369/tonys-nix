{
  config,
  lib,
  pkgs,
}: let
  formats = {
    json = pkgs.formats.json {};
    toml = pkgs.formats.toml {};
  };
  source = import ../source-of-truth {inherit lib;};
  settingsSync = import ./settings-sync.nix {inherit lib pkgs;};
  mcp = import ./mcp.nix {inherit lib;} config.programs.mcp.servers;

  mkFile = {
    format,
    name,
    value,
  }:
    formats.${format}.generate name value;

  mkSettingsFile = {
    provider,
    format,
    name,
    baseHooks ? {},
    render,
  }:
    mkFile {
      inherit format name;
      value = render {
        hooks = baseHooks;
        mcp = mcp.${provider};
      };
    };

  mkSync = {
    type ? "json",
    name,
    target,
    source,
    preserveTomlKeys ? [],
    obsoleteFiles ? [],
  }:
    if type == "json"
    then settingsSync.mkJsonSync {inherit name target source;}
    else if type == "toml"
    then
      settingsSync.mkTomlSync {
        inherit name target source;
        preserveKeys = preserveTomlKeys;
        inherit obsoleteFiles;
      }
    else settingsSync.mkFileCopy {inherit name target source;};
in {
  inherit source mcp mkFile mkSettingsFile mkSync;
  inherit (source) providerHooks;

  mkSettingsSync = {
    provider,
    format,
    fileName,
    syncName,
    target,
    type ? "json",
    baseHooks ? {},
    preserveTomlKeys ? [],
    obsoleteFiles ? [],
    render,
  }: let
    rendered = mkSettingsFile {
      inherit provider format baseHooks render;
      name = fileName;
    };
  in
    mkSync {
      inherit type target preserveTomlKeys;
      inherit obsoleteFiles;
      name = syncName;
      source = "${rendered}";
    };
}
