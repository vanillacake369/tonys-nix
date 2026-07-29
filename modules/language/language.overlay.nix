# NOTE:
# Terraform은 provider lock보다 더 아래쪽의 state schema와 맞물린다.
# flake 전체 nixpkgs bump에 같이 끌려 올라가면 plan은 멀쩡해 보여도
# state write 시점에 팀 단위 복구전을 시작할 수 있다. bump는 별도 작업이다.
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

  # NOTE:
  # Java LSP/build 도구는 한 프로세스 트리 안에서 JDK가 갈라지면 조용히
  # 다른 classpath와 runtime을 본다. jdtls의 Java 21 요구사항에 맞춰
  # formatter, lombok, gradle까지 zulu21에 묶어 split-runtime을 막는다.
  jdt-language-server = prev.jdt-language-server.override {jdk = prev.zulu21;};
  google-java-format = prev.google-java-format.override {jre = prev.zulu21;};
  lombok = prev.lombok.override {jdk = prev.zulu21;};
  gradle = prev.gradle.override {
    gradle-unwrapped = prev.gradle-unwrapped.override {java = prev.zulu21;};
  };

  # NOTE:
  # Node 기반 LSP와 formatter는 wrapper 안의 nodejs-slim까지 같이 탄다.
  # 선언 버전과 내장 runtime이 다르면 경고는 작고 원인은 멀어진다. 여기서는
  # nodejs_24를 하나의 runtime 계층으로 고정한다.
  typescript-language-server = prev.typescript-language-server.override {nodejs = prev.nodejs_24;};
  prettier = prev.prettier.override {nodejs = prev.nodejs_24;};
  bash-language-server = prev.bash-language-server.override {nodejs-slim = prev.nodejs-slim_24;};
  pnpm = prev.pnpm.override {nodejs = prev.nodejs_24;};

  # WARNING:
  # python-lsp-server는 현재 nixpkgs의 jedi 상한과 충돌한다. 이 relaxation은
  # 개발 편의용 우회이며, upstream 제약이 풀리면 제거하는 쪽이 정답이다.
  python313Packages = prev.python313Packages.overrideScope (_pyFinal: pyPrev: {
    python-lsp-server = pyPrev.python-lsp-server.overridePythonAttrs (_: {
      pythonRelaxDeps = ["jedi"];
      doCheck = false;
    });
  });
}
