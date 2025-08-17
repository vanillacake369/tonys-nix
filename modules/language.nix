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
    # Python
    uv
    # Node.js (for Mason LSP installations)
    nodejs_20
    # Rust (for cargo-based tools)
    cargo
    rustc
    # Nix development tools
    nixd              # Nix language server
    alejandra         # Nix formatter
  ];
  home.sessionVariables = {
    JAVA_HOME = "${pkgs.zulu17}";
  };
}
