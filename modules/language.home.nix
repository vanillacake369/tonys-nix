# Language package lists, grouped for review and installed in attribute-name order.
#
{
  pkgs,
  lib,
  ...
}: let
  languagePackages = {
    # =========================================================================
    # 1. General-Purpose & Systems Languages
    # =========================================================================
    # Java 17은 프로젝트용, Java 25는 jdtls 등 편집기 도구용이다.
    java = [
      pkgs.javaProjectJdk
      pkgs.gradle
      pkgs.maven
      pkgs.jdt-language-server
      pkgs.google-java-format
      pkgs.lombok
      pkgs.vscode-extensions.vscjava.vscode-java-debug
      pkgs.vscode-extensions.vscjava.vscode-java-test
    ];

    go = [
      pkgs.go
      (lib.hiPrio pkgs.gotools)
      pkgs.gopls
      pkgs.golangci-lint
      pkgs.delve
    ];

    rust = [
      pkgs.cargo
      pkgs.rustc
      pkgs.rustfmt
      pkgs.clippy
      pkgs.rust-analyzer
      pkgs.cargo-nextest
      pkgs.cargo-watch
      pkgs.cargo-expand
      pkgs.bacon
    ];

    # NOTE: pkgs.gcc 추가 시 clang-tools가 gcc를 찾지 못하는 문제 발생
    # NOTE: nvim-dap C/C++ 디버깅(CodeLLDB)을 위해 vscode-lldb 포함
    c = [
      pkgs.clang-tools
      pkgs.bear
      pkgs.vscode-extensions.vadimcn.vscode-lldb
    ];

    python = [
      (pkgs.python314.withPackages (py: [
        py.uv
        py.pytest
        py.sqlalchemy
        py.pydantic
        py.pydantic-settings
        py.pyyaml
        py.pymysql
        py.testcontainers
        py.python-lsp-server
        py.ruff
        py.uvicorn
        py.pip
        py.lizard
      ]))
    ];

    typescript = [
      pkgs.nodejs_24
      pkgs.typescript-language-server
      pkgs.prettier
      pkgs.biome
      pkgs.pnpm
      pkgs.vscode-js-debug
    ];

    lua = [
      pkgs.lua54Packages.lua
      pkgs.lua54Packages.luaunit
      pkgs.lua54Packages.busted
      pkgs.lua54Packages.mobdebug
      pkgs.lua-language-server
      pkgs.stylua
      pkgs.selene
    ];

    # =========================================================================
    # 2. Shell Scripting & Task Runners
    # =========================================================================
    bash = [
      pkgs.bash-language-server
      pkgs.shfmt
      pkgs.shellcheck
    ];

    just = [
      pkgs.just
      pkgs.just-lsp
    ];

    go-task = [
      pkgs.go-task
    ];

    # =========================================================================
    # 3. Infrastructure, Containers & DevOps
    # =========================================================================
    terraform = [
      pkgs.opentofu
      pkgs.terraform
      pkgs.terragrunt
      pkgs.terraform-ls
      pkgs.tflint
      pkgs.tftui
      pkgs.tflint
      pkgs.trivy
      pkgs.infracost
    ];

    pulumi = [
      pkgs.pulumi
    ];

    ansible = [
      pkgs.ansible
    ];

    docker = [
      pkgs.dockerfile-language-server
      pkgs.docker-compose-language-service
      pkgs.hadolint
    ];

    helm = [
      pkgs.helm-ls
    ];

    # =========================================================================
    # 4. Configuration, Data Formats & Markup
    # =========================================================================
    nix = [
      pkgs.nixd
      pkgs.alejandra
      pkgs.statix
      pkgs.deadnix
    ];

    yaml = [
      pkgs.yamllint
      pkgs.yaml-language-server
      pkgs.yamlfmt
    ];

    toml = [
      pkgs.taplo
    ];

    html = [
      pkgs.vscode-langservers-extracted
    ];
  };

  langPackages = lib.concatLists (lib.attrValues languagePackages);

  # Tools not tied to a single language.
  # nvim-treesitter parser builds
  # shell hook test runner
  commonTools = with pkgs; [
    tree-sitter
    gnumake
    bats
  ];
in {
  home = {
    sessionVariables = {
      # -----------------------------------------------------------------------
      # Java project runtime
      # -----------------------------------------------------------------------
      #
      # 터미널, Maven, Gradle 프로젝트는 Java 17을 기본값으로 본다.
      # jdtls 등 Java 25가 필요한 도구는 overlay의 toolingJdk로 격리된다.
      JAVA_HOME = "${pkgs.javaProjectJdk}";
      # Appended to every JVM (jdtls, gradle daemon, maven, ...). Survives
      # per-project `org.gradle.jvmargs` overrides, which would otherwise
      # replace (not merge) any encoding flag set in user gradle.properties.
      JAVA_TOOL_OPTIONS = "-Dfile.encoding=UTF-8";
      RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
    };
    packages = langPackages ++ commonTools;
    file.".cargo/config.toml".source = ../dotfiles/cargo/config.toml;
    file.".gradle/gradle.properties".text = ''
      org.gradle.daemon.idletimeout=300000
      # Gradle daemon 이 Java 21(jdtls runtime)으로 실행돼도 Nix store 의
      # 프로젝트 JDK 17 을 toolchain 으로 찾을 수 있게 경로를 명시한다.
      # Nix JDK 는 macOS 표준 설치 폴더 밖이라 자동 탐지만으로는 부족하다.
      org.gradle.java.installations.paths=${pkgs.javaProjectJdk}
    '';
    file.".local/share/nvim/neotest-java/junit-platform-console-standalone-6.0.3.jar".source =
      pkgs.neotest-java-junit-platform-console-standalone;
  };
}
