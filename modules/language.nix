{ pkgs, ... }:
{

  home.packages = with pkgs; [
    zulu17
    gradle
    just
    go
    gotools
    gofumpt
    gcc
    lua54Packages.lua
    lua54Packages.luaunit
    stylua
    nixd
    nixfmt-rfc-style
    alejandra
  ];
  home.sessionVariables = {
    JAVA_HOME = "${pkgs.zulu17}";
  };
}
