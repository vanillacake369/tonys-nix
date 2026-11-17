# NOTE:
# Terraform은 provider lock보다 더 아래쪽의 state schema와 맞물린다.
# flake 전체 nixpkgs bump에 같이 끌려 올라가면 plan은 멀쩡해 보여도
# state write 시점에 팀 단위 복구전을 시작할 수 있다. bump는 별도 작업이다.
_final: prev: let
  # ---------------------------------------------------------------------------
  # Java runtime policy
  # ---------------------------------------------------------------------------
  #
  # 프로젝트 런타임과 개발 도구 런타임은 같은 역할이 아니다.
  # - projectJdk : 프로젝트의 Java 17 런타임
  # - toolingJdk : editor and formatter tools run on a newer runtime
  # 둘을 하나로 합치면 프로젝트 호환성 또는
  # 에디터 진단 중 하나가 깨지므로
  # 별도의 두 값을 따로두어 각각의 관심사를 처리하도록 한다.
  projectJdk = prev.zulu17;
  toolingJdk = prev.jdk25;
  inherit (prev) stdenv;
in {
  # Home Manager도 같은 정책을 소비하도록 패키지 집합에 역할 이름을 공개한다.
  # projectJdk는 셸의 기본 JDK이고 toolingJdk는 도구 래퍼 내부 전용이다.
  javaProjectJdk = projectJdk;
  javaToolingJdk = toolingJdk;

  # Keep this recipe self-contained.  `overrideAttrs` inherits the current
  # nixpkgs Terraform recipe, including its Go module layout.  The 1.15.2
  # vendor hash was produced as a normal vendor tree, whereas recent nixpkgs
  # Terraform uses a file GOPROXY (`proxyVendor = true`).  Mixing those two
  # contracts yields a cache that is valid but unreadable by the final build.
  terraform = prev.buildGoModule rec {
    pname = "terraform";
    version = "1.15.2";
    src = prev.fetchFromGitHub {
      owner = "hashicorp";
      repo = "terraform";
      rev = "v${version}";
      hash = "sha256-jwmyZJHGfi2oO8FBebPKBQdXt61w02H6zbbqSXxMhMM=";
    };

    # This exact hash is a `go mod vendor` tree, not a Go proxy cache.
    proxyVendor = false;
    vendorHash = "sha256-Gv6V5aXqTuQoG1StbD/7Ln2QrLpMsW6fbUJUkyZMkvk=";

    # Keep Nix-provided provider wrappers discoverable without inheriting the
    # moving patch set from the current nixpkgs Terraform package.
    postPatch = ''
      substituteInPlace internal/command/init_run.go \
        --replace-fail $'\t"fmt"\n\t"strings"' $'\t"fmt"\n\t"os"\n\t"strings"' \
        --replace-fail $'\tif c.forceInitCopy {\n\t\tc.migrateState = true\n\t}\n' $'\tif c.forceInitCopy {\n\t\tc.migrateState = true\n\t}\n\n\tif val, ok := os.LookupEnv("NIX_TERRAFORM_PLUGIN_DIR"); ok {\n\t\tinitArgs.PluginPath = append(initArgs.PluginPath, val)\n\t}\n'
    '';

    # Terraform's vendored speakeasy package hardcodes /bin/stty, which is
    # absent on Nix hosts.  This runs after the checked vendor tree is copied
    # into the build source, so it intentionally does not change vendorHash.
    postConfigure = ''
      substituteInPlace vendor/github.com/bgentry/speakeasy/speakeasy_unix.go \
        --replace-fail "/bin/stty" "${prev.coreutils}/bin/stty"
    '';

    env.CGO_ENABLED = if stdenv.hostPlatform.isDarwin then "1" else "0";
    ldflags = [
      "-s"
      "-w"
      "-X 'github.com/hashicorp/terraform/version.dev=no'"
    ];

    nativeBuildInputs = [prev.installShellFiles];
    postInstall = ''
      installShellCompletion --bash --name terraform <(echo complete -C terraform terraform)
    '';

    preCheck = ''
      export HOME=$TMPDIR
      export TF_SKIP_REMOTE_TESTS=1
    '';
    subPackages = ["."];

    __darwinAllowLocalNetworking = true;

    meta = {
      description = "Tool for building, changing, and versioning infrastructure";
      homepage = "https://www.terraform.io/";
      changelog = "https://github.com/hashicorp/terraform/blob/v${version}/CHANGELOG.md";
      license = prev.lib.licenses.bsl11;
      mainProgram = "terraform";
    };
  };

  # ---------------------------------------------------------------------------
  # Java tooling runtime
  # ---------------------------------------------------------------------------
  #
  # 에디터 도구는 JAVA_HOME=17인 셸에서도 독립적으로 기동해야 한다.
  # jdtls와 같은 프로세스 트리에서 동작하는 formatter와 lombok도 25에 묶어
  # 도구별 classpath와 runtime이 조용히 갈라지는 것을 막는다.
  jdt-language-server = prev.jdt-language-server.override {jdk25 = toolingJdk;};
  google-java-format = prev.google-java-format.override {jre = toolingJdk;};
  lombok = prev.lombok.override {jdk = toolingJdk;};

  # ---------------------------------------------------------------------------
  # Java project runtime
  # ---------------------------------------------------------------------------
  #
  # Global Gradle runs on the project runtime. Repository-local gradlew
  # wrappers still choose their own Gradle version while keeping this JDK.
  gradle = prev.gradle.override {java = projectJdk;};
  neotest-java-junit-platform-console-standalone = prev.fetchurl {
    url = "https://repo1.maven.org/maven2/org/junit/platform/junit-platform-console-standalone/6.0.3/junit-platform-console-standalone-6.0.3.jar";
    hash = "sha256-O6DWFQr3khShQR+eovvvhk7vaLaMiaF/ZywLib/506I=";
  };

  # NOTE:
  # Node 기반 LSP와 formatter는 wrapper 안의 nodejs-slim까지 같이 탄다.
  # 선언 버전과 내장 runtime이 다르면 경고는 작고 원인은 멀어진다. 여기서는
  # nodejs_24를 하나의 runtime 계층으로 고정한다.
  # pnpm은 현재 nixpkgs 구현에서 nodejs override를
  # 지원하지 않으므로 upstream 패키지 정의를 그대로 따른다.
  typescript-language-server = prev.typescript-language-server.override {nodejs = prev.nodejs_24;};
  prettier = prev.prettier.override {nodejs = prev.nodejs_24;};
  bash-language-server = prev.bash-language-server.override {nodejs-slim = prev.nodejs-slim_24;};
  inherit (prev) pnpm;

  # Bear 4.2.3의 process-tree signal integration test는 Darwin builder에서
  # grandchild PID 기록 전에 타임아웃되는 비결정적 실패가 있다. 전체 check를
  # 끄지 않고 해당 Cargo test case만 Darwin에서 제외한다.
  bear = prev.bear.overrideAttrs (old: {
    cargoTestFlags =
      (old.cargoTestFlags or [])
      ++ prev.lib.optionals stdenv.hostPlatform.isDarwin [
        "--"
        "--skip"
        "cases::exit_codes::signal_tears_down_build_process_tree"
      ];
    # nixpkgs 4.2.3 expression assumes the Linux cdylib suffix in postInstall.
    # Preserve the upstream install layout while selecting Darwin's actual file.
    postInstall =
      builtins.replaceStrings
      ["mv $out/lib/libexec.so $out/libexec/bear/lib/"]
      [
        "mv $out/lib/${
          if stdenv.hostPlatform.isDarwin
          then "libexec.dylib"
          else "libexec.so"
        } $out/libexec/bear/lib/"
      ]
      old.postInstall;
  });

  lua54Packages = prev.lua54Packages.overrideScope (luaFinal: _luaPrev: {
    mobdebug = luaFinal.callPackage (
      {
        buildLuarocksPackage,
        fetchFromGitHub,
        fetchurl,
        luaAtLeast,
        luaOlder,
        luasocket,
      }:
        buildLuarocksPackage {
          pname = "mobdebug";
          version = "0.80-1";
          knownRockspec =
            (fetchurl {
              url = "https://luarocks.org/mobdebug-0.80-1.rockspec";
              hash = "sha256-FxtnsnQDm1ok8fki4sWR3AHPUPWOUGucEcoJsIFoMfk=";
            }).outPath;
          src = fetchFromGitHub {
            owner = "pkulchenko";
            repo = "MobDebug";
            rev = "0.80";
            hash = "sha256-Z3OoDXK5t1MQUHx8Muvp9Fl43yqDgxnWBuAQxEUYwrk=";
          };

          disabled = luaOlder "5.1" || luaAtLeast "5.5";

          propagatedBuildInputs = [
            luasocket
          ];

          meta = {
            homepage = "https://github.com/pkulchenko/MobDebug";
            description = "Remote debugger for the Lua programming language";
            license.fullName = "MIT/X11";
          };
        }
    ) {};
  });

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
