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

    java = {
      extensions = ["java"];
      packages = [
        pkgs.zulu21
        pkgs.gradle
        pkgs.maven
        pkgs.jdt-language-server
        pkgs.google-java-format
        pkgs.lombok
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
        pkgs.gcc
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
      ];
      format = "cargo fmt --check";
      lint = "cargo clippy -- -D warnings";
      diagnose = "cargo check";
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
        pkgs.taplo
      ];
      lint = "yamllint";
    };

    typescript = {
      extensions = ["ts" "tsx" "js" "jsx" "mjs" "cjs"];
      packages = [
        pkgs.nodejs_24
        pkgs.typescript-language-server
        pkgs.prettier
        pkgs.biome
        pkgs.pnpm
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
        pkgs.black
        pkgs.ruff
      ];
      format = "black --check";
      lint = "ruff check";
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
      JAVA_HOME = "${pkgs.zulu21}";
      # Appended to every JVM (jdtls, gradle daemon, maven, ...). Survives
      # per-project `org.gradle.jvmargs` overrides, which would otherwise
      # replace (not merge) any encoding flag set in user gradle.properties.
      JAVA_TOOL_OPTIONS = "-Dfile.encoding=UTF-8";
      RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
    };
    packages = langPackages ++ commonTools;
    file.".claude/lang-tools.json".source = jsonFormat.generate "lang-tools.json" toolTable;
    file.".gradle/gradle.properties".text = ''
      org.gradle.daemon.idletimeout=300000
    '';
    # Required by neotest-java at runtime. Plugin doesn't bundle the JAR and
    # otherwise prompts for `:NeotestJava setup` on every fresh machine.
    #
    # NOTE:
    # [VERSION DRIFT]
    # this is pinned to 6.0.3 (the version neotest-java expects
    # as of plugin tag v0.37.3). When neotest-java updates and bumps its
    # expected version, the symlink filename will no longer match and the
    # plugin falls back to its interactive setup. Detection signal: `:Lazy log
    # neotest-java` shows a version bump → update both URL and hash here (run
    # `nix-prefetch-url` on the new URL to get the new hash).
    file.".local/share/nvim/neotest-java/junit-platform-console-standalone-6.0.3.jar".source = pkgs.fetchurl {
      url = "https://repo1.maven.org/maven2/org/junit/platform/junit-platform-console-standalone/6.0.3/junit-platform-console-standalone-6.0.3.jar";
      hash = "sha256-O6DWFQr3khShQR+eovvvhk7vaLaMiaF/ZywLib/506I=";
    };
  };
}
