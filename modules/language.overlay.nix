# Pin terraform — state file format locks to version; accidental upgrade can corrupt state.
_final: prev: {
  terraform = prev.terraform.overrideAttrs (_old: rec {
    version = "1.15.2";
    src = prev.fetchFromGitHub {
      owner = "hashicorp";
      repo = "terraform";
      rev = "v${version}";
      hash = "sha256-jwmyZJHGfi2oO8FBebPKBQdXt61w02H6zbbqSXxMhMM=";
    };
    vendorHash = "sha256-Gv6V5aXqTuQoG1StbD/7Ln2QrLpMsW6fbUJUkyZMkvk=";
  });

  # Pin Java toolchain to zulu21 — jdtls requires Java 21+ (raises Exception if major < 21),
  # and all Java LSP/build tools must share the same JDK to avoid split-runtime conflicts.
  jdt-language-server = prev.jdt-language-server.override {jdk = prev.zulu21;};
  google-java-format = prev.google-java-format.override {jre = prev.zulu21;};
  lombok = prev.lombok.override {jdk = prev.zulu21;};
  gradle = prev.gradle.override {
    gradle-unwrapped = prev.gradle-unwrapped.override {java = prev.zulu21;};
  };

  # Pin Node.js toolchain to nodejs_24 — nixpkgs default is 24.x and all bundled LSP servers
  # ship nodejs-slim-24 internally; aligning the declared version eliminates split-runtime warnings.
  typescript-language-server = prev.typescript-language-server.override {nodejs = prev.nodejs_24;};
  prettier = prev.prettier.override {nodejs = prev.nodejs_24;};
  bash-language-server = prev.bash-language-server.override {nodejs-slim = prev.nodejs-slim_24;};
  pnpm = prev.pnpm.override {nodejs = prev.nodejs_24;};

  # Fix python-lsp-server: requires jedi<0.20.0 but nixpkgs ships 0.20.0
  python313Packages = prev.python313Packages.overrideScope (_pyFinal: pyPrev: {
    python-lsp-server = pyPrev.python-lsp-server.overridePythonAttrs (_: {
      pythonRelaxDeps = ["jedi"];
      doCheck = false;
    });
  });
}
