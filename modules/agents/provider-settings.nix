{
  config,
  lib,
  pkgs,
}: let
  formats = {
    json = pkgs.formats.json {};
    toml = pkgs.formats.toml {};
  };
  settingsSync = import ./mutable-settings-sync.nix {inherit lib pkgs;};
  mcpAdapt = import ./mcp-adapters.nix {inherit lib;} config.programs.mcp.servers;
  providerHooks = import ./policy-provider-hooks.nix {inherit lib;};

  # Combine generated policy hooks with each provider's native hook shape.
  # Provider modules pass only their base settings; this layer attaches MCP and
  # rendered policy hooks before writing the final config file.
  mkHooks = provider: baseHooks:
    providerHooks.mergeHooks baseHooks (config.agentPolicy._assembledHooks.${provider} or {});

  # Pick the activation writer by target file semantics.
  # JSON/TOML targets preserve selected mutable state; raw files are copied over
  # after backing up the previous value.
  mkSync = {
    type ? "json",
    name,
    target,
    source,
    preserveTomlKeys ? [],
  }:
    if type == "json"
    then
      settingsSync.mkJsonSync {
        inherit name target source;
      }
    else if type == "toml"
    then
      settingsSync.mkTomlSync {
        inherit name target source;
        preserveKeys = preserveTomlKeys;
      }
    else
      settingsSync.mkFileCopy {
        inherit name target source;
      };

  # Generate a Nix-store settings file in the provider's native format.
  # The mutable sync layer owns copying and merge behavior during activation.
  mkFile = {
    format,
    name,
    value,
  }:
    formats.${format}.generate name value;

  # Render provider settings with policy hooks and adapted MCP servers.
  # Callers keep provider-specific shape in `render`; shared plumbing stays here.
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

  # One-shot helper for the common provider settings path.
  # It renders the generated source file, then syncs it into the mutable config
  # location used by the CLI at runtime.
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
