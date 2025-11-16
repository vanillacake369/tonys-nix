{pkgs, ...}: {
  home.packages = with pkgs; [
    # Java
    zulu17
    gradle
    jdt-language-server

    # Just
    just

    # Make
    gnumake

    # Go
    go
    gotools
    gopls

    # Lua
    gcc
    lua54Packages.lua
    lua54Packages.luaunit
    lua-language-server

    # Rust (for cargo-based tools)
    cargo
    rustc

    # Nix development tools
    nixd
    alejandra

    # YAML
    yamllint
    yaml-language-server

    # TypeScript/JavaScript
    nodejs_22
    nodePackages.typescript-language-server
  ];
  home.sessionVariables = {
    JAVA_HOME = "${pkgs.zulu17}";
  };
}
