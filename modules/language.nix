{pkgs, ...}: {
  home.packages = with pkgs; [
    # Java
    zulu17
    gradle
    # Just
    just
    # Make
    gnumake
    # Go
    go
    gotools
    # Lua
    gcc
    lua54Packages.lua
    lua54Packages.luaunit
    # Nix
    nixfmt-rfc-style
    # Python
    uv
    # Formatters
    nodePackages.prettier
  ];
  home.sessionVariables = {
    JAVA_HOME = "${pkgs.zulu17}";
  };
}
