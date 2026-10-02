# Per-language tooling SSoT + home-manager wiring.
#
# `languages` is the single source consumed by:
#   - home.packages          (every entry's `packages`)
#   - ~/.claude/lang-tools.json  (ext → {format?,lint?,diagnose?}), read by
#       auto-lint.sh (format/lint) + semantic-oracle.sh (diagnose)
#
# Per entry: extensions (json keys), packages (nix pkgs),
#            format/lint/diagnose (optional shell command strings).
# nix is intentionally given no `diagnose`: live-oracle already runs
# `nix flake check`, so duplicating it here would double-gate.
{
  pkgs,
  lib,
  ...
}: let
  languages = {
    bash = {
      extensions = ["sh" "bash"];
      packages = [
        pkgs.bash-language-server
        pkgs.shfmt
        pkgs.shellcheck
      ];
      format = "shfmt -d";
      lint = "shellcheck -f gcc";
    };

    # Java 21 is kept as the project JDK and for the jdtls Neovim wrapper.
    java = {
      extensions = ["java"];
      packages = [
        # Project/runtime
        pkgs.javaProjectJdk
        pkgs.gradle
        pkgs.maven
        # LSP/tooling
        pkgs.jdt-language-server
        pkgs.google-java-format
        pkgs.lombok
        # JDT LS debug/test bundles
        pkgs.vscode-extensions.vscjava.vscode-java-debug
        pkgs.vscode-extensions.vscjava.vscode-java-test
      ];
      format = "google-java-format --dry-run --set-exit-if-changed";
    };

    just = {
      extensions = ["just"];
      packages = [
        pkgs.just
        pkgs.just-lsp
      ];
    };

    go = {
      extensions = ["go"];
      packages = [
        pkgs.go
        (lib.hiPrio pkgs.gotools)
        pkgs.gopls
        pkgs.golangci-lint
        pkgs.delve
      ];
      format = "gofmt -l";
      diagnose = "go build ./...";
    };

    c = {
      extensions = ["c" "h" "cpp" "hpp" "cc"];
      packages = [
        # pkgs.gcc
        pkgs.clang-tools
        pkgs.bear
      ];
      format = "clang-format --dry-run --Werror";
    };

    lua = {
      extensions = ["lua"];
      packages = [
        pkgs.lua54Packages.lua
        pkgs.lua54Packages.luaunit
        pkgs.lua54Packages.busted
        pkgs.lua54Packages.mobdebug
        pkgs.lua-language-server
        pkgs.stylua
        pkgs.selene
      ];
      format = "stylua --check";
      lint = "selene";
    };

    rust = {
      extensions = ["rs"];
      packages = [
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
      format = "cargo fmt --check";
      lint = "cargo clippy -- -D warnings";
      diagnose = "cargo check";
    };

    python = {
      extensions = ["py" "pyi"];
      packages = [
        pkgs.uv
        pkgs.python313Packages.python-lsp-server
        pkgs.python313Packages.python
        pkgs.python313Packages.pytest
        pkgs.python313Packages.ruff
        pkgs.python313Packages.uvicorn
        pkgs.python313Packages.pip
        pkgs.python313Packages.lizard
        pkgs.black
        pkgs.ruff
      ];
      format = "black --check";
      lint = "ruff check";
    };

    nix = {
      extensions = ["nix"];
      packages = [
        pkgs.nixd
        pkgs.alejandra
        pkgs.statix
        pkgs.deadnix
      ];
      format = "alejandra --check";
      lint = "statix check";
    };

    yaml = {
      extensions = ["yaml" "yml"];
      packages = [
        pkgs.yamllint
        pkgs.yaml-language-server
        pkgs.yamlfmt
        pkgs.helm-ls
      ];
      lint = "yamllint";
    };

    helm = {
      extensions = [];
      packages = [
        pkgs.helm-ls
      ];
    };

    toml = {
      extensions = ["toml"];
      packages = [
        pkgs.taplo
      ];
      format = "taplo fmt --check";
    };

    typescript = {
      extensions = ["ts" "tsx" "js" "jsx" "mjs" "cjs"];
      packages = [
        pkgs.nodejs_24
        pkgs.typescript-language-server
        pkgs.prettier
        pkgs.biome
        pkgs.pnpm
        pkgs.vscode-js-debug
      ];
      format = "prettier --check";
      diagnose = "tsc --noEmit";
    };

    ansible = {
      extensions = [];
      packages = [
        pkgs.ansible
      ];
    };

    terraform = {
      extensions = ["tf" "tfvars"];
      packages = [
        pkgs.terraform
        pkgs.terraform-ls
        pkgs.tflint
      ];
      format = "terraform fmt -check";
    };

    pulumi = {
      extensions = ["yaml" "yml"];
      packages = [
        pkgs.pulumi
      ];
    };

    docker = {
      extensions = ["dockerfile"];
      packages = [
        pkgs.docker-compose-language-service
        pkgs.hadolint
      ];
      lint = "hadolint";
    };

    html = {
      extensions = ["html"];
      packages = [
        pkgs.vscode-langservers-extracted
      ];
    };
  };

  langPackages = lib.concatMap (l: l.packages) (lib.attrValues languages);

  # Tools not tied to a single language.
  commonTools = with pkgs; [
    tree-sitter # nvim-treesitter parser builds
    gnumake
    bats # shell hook test runner
  ];

  # ext → { format?, lint?, diagnose? } — consumed by auto-lint.sh + semantic-oracle.sh
  toolEntry = l:
    lib.filterAttrs (_: v: v != null) {
      format = l.format or null;
      lint = l.lint or null;
      diagnose = l.diagnose or null;
    };
  toolTable =
    lib.foldl'
    (acc: l: acc // lib.genAttrs l.extensions (_: toolEntry l))
    {}
    (lib.attrValues languages);

  jsonFormat = pkgs.formats.json {};
in {
  home = {
    sessionVariables = {
      # -----------------------------------------------------------------------
      # Java project runtime
      # -----------------------------------------------------------------------
      #
      # 터미널, Maven, Gradle 프로젝트는 Java 17을 기본값으로 본다.
      # jdtls 등 Java 21이 필요한 도구는 overlay의 toolingJdk로 격리된다.
      JAVA_HOME = "${pkgs.javaProjectJdk}";
      # Appended to every JVM (jdtls, gradle daemon, maven, ...). Survives
      # per-project `org.gradle.jvmargs` overrides, which would otherwise
      # replace (not merge) any encoding flag set in user gradle.properties.
      JAVA_TOOL_OPTIONS = "-Dfile.encoding=UTF-8";
      RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
    };
    packages = langPackages ++ commonTools;
    file.".cargo/config.toml".source = ../../dotfiles/cargo/config.toml;
    file.".claude/lang-tools.json".source = jsonFormat.generate "lang-tools.json" toolTable;
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
