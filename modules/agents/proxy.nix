# cli-proxy-api: unified AI provider proxy
# Provides: localhost:4001 with OpenAI/Claude/Gemini compatible endpoints
# Used by: Claude hooks (Pattern A) + Bash delegation (Pattern B)
{pkgs, ...}: {
  home.packages = [
    pkgs.llm-agents.cli-proxy-api
  ];

  # Proxy config
  home.file.".cli-proxy-api/config.yaml".text = ''
    server:
      port: 4001
      host: 127.0.0.1

    providers:
      gemini:
        enabled: true
      codex:
        enabled: true

    routing:
      default_provider: gemini
      fallback_enabled: true

    logging:
      enabled: true
      level: info
  '';

  # macOS: auto-start proxy via launchd
  launchd.agents.cli-proxy-api = {
    enable = true;
    config = {
      Label = "com.cli-proxy-api";
      ProgramArguments = ["${pkgs.llm-agents.cli-proxy-api}/bin/cli-proxy-api"];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/cli-proxy-api.log";
      StandardErrorPath = "/tmp/cli-proxy-api.err";
      EnvironmentVariables = {
        HOME = "\${HOME}";
      };
    };
  };
}
