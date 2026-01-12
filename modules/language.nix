{pkgs, ...}: {
  # Java environment
  home.sessionVariables = {
    JAVA_HOME = "${pkgs.zulu17}";
  };

  home.packages = with pkgs; [
    # Bash
    bash-language-server
    shfmt
    shellcheck

    # Java
    zulu17
    gradle
    jdt-language-server
    google-java-format

    # Just
    just
    just-lsp

    # Make
    gnumake

    # Go
    go
    gotools
    gopls
    golangci-lint

    # C
    gcc
    clang-tools

    # Lua
    lua54Packages.lua
    lua54Packages.luaunit
    lua-language-server
    stylua
    selene

    # Rust
    cargo
    rustc

    # Nix
    nixd
    alejandra
    statix
    deadnix

    # YAML
    yamllint
    yaml-language-server
    yamlfmt

    # TypeScript/JavaScript
    nodejs_22
    nodePackages.typescript-language-server
    nodePackages.prettier
    biome

    # Terraform
    terraform
    terraform-ls
    tflint

    # Python
    uv
    python313Packages.python-lsp-server
    black
    ruff

    # Docker
    docker-compose-language-service
    hadolint

    # HTML
    vscode-langservers-extracted
  ];
}
