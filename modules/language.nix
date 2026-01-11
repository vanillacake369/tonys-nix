{pkgs, ...}: {
    # Java environment
    home.sessionVariables = {
        JAVA_HOME = "${pkgs.zulu17}";
    };

    home.packages = with pkgs; [
        # Bash
        bash-language-server

        # Java
        zulu17
        gradle
        jdt-language-server

        # Just
        just
        just-lsp

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
        nil
        nixd
        alejandra

        # YAML
        yamllint
        yaml-language-server

        # TypeScript/JavaScript
        nodejs_22
        nodePackages.typescript-language-server

        # Terraform
        terraform
        terraform-ls

        # Python
        uv
        python313Packages.python-lsp-server

        # Docker
        docker-compose-language-service

        # HTML
        vscode-langservers-extracted
    ];
}
