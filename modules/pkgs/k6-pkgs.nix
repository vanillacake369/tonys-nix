{ pkgs, ... }: {
  home.packages = with pkgs; [
    k6
  ];
}

