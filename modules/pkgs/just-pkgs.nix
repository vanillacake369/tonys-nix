{ pkgs, ... }: {
  home.packages = with pkgs; [
    # Command runner
    just
  ];
}

