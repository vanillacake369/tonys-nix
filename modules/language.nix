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
    gofumpt
    # Lua
    gcc
    lua54Packages.lua
    lua54Packages.luaunit
    stylua
    # Nix
    nixd
    nixfmt-rfc-style
    alejandra
    # Python
    uv
    # Formatters
    nodePackages.prettier
  ];
  home.sessionVariables = {
    JAVA_HOME = "${pkgs.zulu17}";
  };
}
