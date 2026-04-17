{pkgs, ...}: {
  # Java environment
  home.sessionVariables = {
    JAVA_HOME = "${pkgs.zulu17}";
  };

  home.packages = with pkgs; [
    # Tree-sitter CLI (for nvim-treesitter to build parsers)
    tree-sitter

    # Bash
    bash-language-server
    shfmt
    shellcheck

    # Java
    zulu17
    gradle
    jdt-language-server
    google-java-format
    lombok

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
    delve

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

    # YAML/TOML
    yamllint
    yaml-language-server
    yamlfmt
    taplo

    # TypeScript/JavaScript
    nodejs_22
    typescript-language-server
    prettier
    biome
    pnpm

    # Ansible
    ansible

    # Terraform
    terraform
    terraform-ls
    tflint

    # Python
    uv
    python313Packages.python-lsp-server
    python313Packages.python
    python313Packages.pytest
    python313Packages.ruff
    python313Packages.uvicorn
    python313Packages.pip
    black
    ruff

    # Docker
    docker-compose-language-service
    hadolint

    # HTML
    vscode-langservers-extracted
  ];
}
