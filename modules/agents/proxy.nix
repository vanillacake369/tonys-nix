# cli-proxy-api: unified AI provider proxy
# Provides: localhost:4001 with OpenAI/Claude/Gemini compatible endpoints
# Used by: Claude hooks (Pattern A) + Bash delegation (Pattern B)
{
  config,
  lib,
  pkgs,
  ...
}: let
  configPath = "${config.home.homeDirectory}/.cli-proxy-api/config.yaml";
  authDir = "${config.home.homeDirectory}/.cli-proxy-api";
  cliProxy = "${pkgs.llm-agents.cli-proxy-api}/bin/cli-proxy-api";
in {
  home.packages = [
    pkgs.llm-agents.cli-proxy-api
  ];

  # Proxy config (see https://github.com/router-for-me/CLIProxyAPI/blob/main/config.example.yaml)
  home.file.".cli-proxy-api/config.yaml".text = ''
    host: "127.0.0.1"
    port: 4001
    auth-dir: "~/.cli-proxy-api"
    debug: false
    request-retry: 3
    routing:
      strategy: "round-robin"
    quota-exceeded:
      switch-project: true
      switch-preview-model: true
  '';

  # macOS: auto-start proxy via launchd
  launchd.agents.cli-proxy-api = {
    enable = true;
    config = {
      Label = "com.cli-proxy-api";
      ProgramArguments = ["${pkgs.llm-agents.cli-proxy-api}/bin/cli-proxy-api" "-config" configPath];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/cli-proxy-api.log";
      StandardErrorPath = "/tmp/cli-proxy-api.err";
      EnvironmentVariables = {
        HOME = config.home.homeDirectory;
      };
    };
  };
}
