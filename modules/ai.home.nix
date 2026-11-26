# AI / Agents
#
# NOTE :
# Configs are configured via tonys-agent-harness.
# Only packages are installed here
# https://github.com/vanillacake369/tonys-agent-harness
{pkgs, ...}: {
  home.packages = with pkgs; [
    # Agents
    codex

    # Evalutions
    promptfoo
  ];
}
