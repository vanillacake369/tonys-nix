{ pkgs, ... }: {

  home.packages = with pkgs; [
    zulu17
    gradle
    just
    go
    k6
    lua
  ];
  home.sessionVariables = {
    JAVA_HOME = "${pkgs.zulu17}";
  };
}

