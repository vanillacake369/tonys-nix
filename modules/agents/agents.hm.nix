{pkgs, ...}: {
  home.packages = with pkgs; [
    # claude-code
    # antigravity-cli
    codex
  ];
}
