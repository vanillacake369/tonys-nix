{
  config,
  lib,
  pkgs,
}: let
  formats = {
    json = pkgs.formats.json {};
    toml = pkgs.formats.toml {};
  };
  sync = import ./sync-mutable-config.nix {inherit lib pkgs;};
  mcpAdapt = import ./mcp-adapters.nix {inherit lib;} config.programs.mcp.servers;
  providerHooks = import ./policy-provider-hooks.nix {inherit lib;};

  mkHooks = provider: baseHooks:
    providerHooks.mergeHooks baseHooks (config.agentPolicy._assembledHooks.${provider} or {});

  mkSync = {
    type ? "json",
    name,
    target,
    source,
    preserveTomlKeys ? [],
  }:
    if type == "json"
    then
      sync.mkJsonSync {
        inherit name target source;
      }
    else if type == "toml"
    then
      sync.mkTomlSync {
        inherit name target source preserveTomlKeys;
      }
    else
      sync.mkFileCopy {
        inherit name target source;
      };

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
  }: let
    hooks = mkHooks provider baseHooks;
    mcp = mcpAdapt.${provider};
  in
    mkFile {
      inherit format name;
      value = render {inherit hooks mcp;};
    };
in {
  inherit providerHooks mkFile mkSettingsFile mkSync;
  mcp = mcpAdapt;

  mkSettingsSync = {
    provider,
    format,
    fileName,
    syncName,
    target,
    type ? "json",
    baseHooks ? {},
    preserveTomlKeys ? [],
    render,
  }: let
    source = mkSettingsFile {
      inherit provider format baseHooks render;
      name = fileName;
    };
  in
    mkSync {
      inherit type target preserveTomlKeys;
      name = syncName;
      source = "${source}";
    };
}
