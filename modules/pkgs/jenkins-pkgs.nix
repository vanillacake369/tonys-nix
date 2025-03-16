{ pkgs, ... }: {
  home.packages = with pkgs; [
    jenkins
  ];
}

