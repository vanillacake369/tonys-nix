_: let
  localUser = builtins.getEnv "TONYS_NIX_DARWIN_USER";
in {
  system.stateVersion = 6;
  nixpkgs.config.allowUnfree = true;
  # just installs Nix and owns /etc/nix/nix.conf via system-link-nix-conf.
  nix.enable = false;

  homebrew = {
    enable = true;
    user =
      if localUser != ""
      then localUser
      else "limjihoon";
    onActivation = {
      autoUpdate = false;
      cleanup = "none";
      upgrade = false;
    };
    taps = [
      "dicklesworthstone/tap"
      "felixkratz/formulae"
      "vanillacake369/tap"
    ];
    brews = [
      "cosign"
      "goreleaser"
      "just"
      "k3d"
      "podman"
      "podman-compose"
      "showkey"
      "slsa-verifier"
      {
        name = "tailscale";
        restart_service = "changed";
      }
    ];
    casks = [
      "brave-browser"
      "karabiner-elements"
      "middleclick"
      "monitorcontrol"
      "multipass"
      "podman-desktop"
      "raycast"
      "scroll-reverser"
      "shottr"
      "ticktick"
      "wezterm"
      # "obs"
      # "blackhole-2ch"
      # "buzz"
      # "cap"
      # "obsidian"
    ];
  };
}
