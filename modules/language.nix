{ pkgs, ... }: {

  home.packages = with pkgs; [
    zulu17
    gradle
    just
    go
    gcc
    lua54Packages.lua
    lua54Packages.luaunit
    nixd
    nixfmt-rfc-style
    # nixfmt-classic
  ];
  home.sessionVariables = {
    JAVA_HOME = "${pkgs.zulu17}";
  };
}

