{ pkgs, ... }: {
  home.packages = with pkgs; [
    awscli
    # awscli2
  ];
}

