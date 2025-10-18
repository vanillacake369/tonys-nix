# Nix configuration, binary caches, and garbage collection
{
  config,
  pkgs,
  lib,
  ...
}: {
  # Nix configuration optimized for performance and SSD longevity
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [
      "root"
      "@wheel"
    ];
    # Performance optimizations
    auto-optimise-store = true; # Enable store deduplication for better performance
    max-jobs = "auto"; # Use all available cores (8 cores detected)
    cores = 0; # Use all available cores per job
    # Binary caches to reduce local builds (removed duplicate cache.nixos.org)
    substituters = [
      "https://cache.nixos.org/"
      "https://nix-community.cachix.org"
      "https://devenv.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
    ];
  };

  # Optimized garbage collection for better performance and SSD longevity
  nix.gc = {
    automatic = true;
    dates = "daily"; # More frequent cleanup for better performance
    options = "--delete-older-than 7d"; # Shorter retention for smaller store size
  };
}
