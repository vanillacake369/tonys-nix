{nixpkgs-java}: _final: prev: let
  inherit (prev) stdenv;
  temurin = nixpkgs-java.legacyPackages.${stdenv.hostPlatform.system};

  # ---------------------------------------------------------------------------
  # Java Runtime Policy
  # ---------------------------------------------------------------------------
  #
  # 2026.11.18 오라클 CSPU 보안 패치에 대한 수동 핀닝
  # https://www.oracle.com/security-alerts/cspunov2026.html#AppendixJAVA
  # 프로젝트 런타임과 에디터 도구 런타임의 관심사를 분리한다.
  # - projectJdk : 프로젝트 빌드 및 실행용 Java 17 (17.0.21.1 이상)
  # - toolingJdk : jdtls, formatter, lombok 등 에디터 도구 전용 Java 25 (25.0.5.1 이상)
  # 둘을 하나로 합치면 프로젝트 호환성이나 에디터 진단 중 하나가 깨지므로 별도로 유지한다.
  mkCorretto = major: version: hash:
    prev.stdenvNoCC.mkDerivation {
      pname = "amazon-corretto-${major}";
      inherit version;

      src = prev.fetchurl {
        url = "https://corretto.aws/downloads/resources/${version}/amazon-corretto-${version}-macosx-aarch64.tar.gz";
        inherit hash;
      };

      dontUnpack = true;
      dontConfigure = true;
      dontBuild = true;

      installPhase = ''
        runHook preInstall

        mkdir -p extracted "$out"
        tar -xzf "$src" -C extracted

        javaBin=$(find extracted -path '*/Contents/Home/bin/java' -print -quit)
        test -n "$javaBin" || {
          echo "Corretto JDK not found" >&2
          exit 1
        }

        jdkHome="''${javaBin%/bin/java}"
        cp -R "$jdkHome"/. "$out"/

        test -x "$out/bin/java"
        test -x "$out/bin/javac"

        runHook postInstall
      '';

      meta = {
        description = "Amazon Corretto ${major} JDK";
        homepage = "https://aws.amazon.com/corretto/";
        license = prev.lib.licenses.gpl2Classpath;
        platforms = ["aarch64-darwin"];
        mainProgram = "java";
      };
    };

  projectJdk =
    if stdenv.hostPlatform.isDarwin
    then
      mkCorretto "17" "17.0.21.1.2"
      "sha256-ER90OACVjksBP0alPH+G3UOggVoMqEB6Uu1pnS2FW2A="
    else temurin.temurin-bin-17;

  toolingJdk = temurin.temurin-bin-25;
in {
  # Home Manager 셸 환경 및 도구 래퍼에서 소비할 역할별 JDK 노출
  javaProjectJdk = projectJdk;
  javaToolingJdk = toolingJdk;

  # ---------------------------------------------------------------------------
  # Terraform (State Schema 보호를 위한 버전 고정)
  # ---------------------------------------------------------------------------
  #
  # Terraform은 provider lock보다 하위 계층인 state schema와 직접 맞물린다.
  # flake 전체 nixpkgs 업데이트 시 함께 버전이 올라가면 plan 단계에서는 문제가
  # 없어 보여도 state write 시점에 팀 단위 복구 장애가 발생할 수 있으므로 별도로 관리한다.
  #
  # NOTE: `overrideAttrs` 대신 자급자족형 `buildGoModule` 레시피를 유지한다.
  # 1.15.2의 vendorHash는 일반 vendor 트리 기준이지만 최신 nixpkgs는 file GOPROXY
  # (`proxyVendor = true`)를 사용하므로, 두 계약을 섞으면 캐시를 읽지 못해 빌드가 실패한다.
  terraform = prev.buildGoModule rec {
    pname = "terraform";
    version = "1.15.2";

    src = prev.fetchFromGitHub {
      owner = "hashicorp";
      repo = "terraform";
      rev = "v${version}";
      hash = "sha256-jwmyZJHGfi2oO8FBebPKBQdXt61w02H6zbbqSXxMhMM=";
    };

    # Go proxy 캐시가 아닌 일반 `go mod vendor` 트리 해시 사용
    proxyVendor = false;
    vendorHash = "sha256-Gv6V5aXqTuQoG1StbD/7Ln2QrLpMsW6fbUJUkyZMkvk=";

    # Nix 환경의 provider wrapper 경로(`NIX_TERRAFORM_PLUGIN_DIR`)를 인식하도록 패치
    postPatch = ''
      substituteInPlace internal/command/init_run.go \
        --replace-fail $'\t"fmt"\n\t"strings"' $'\t"fmt"\n\t"os"\n\t"strings"' \
        --replace-fail $'\tif c.forceInitCopy {\n\t\tc.migrateState = true\n\t}\n' $'\tif c.forceInitCopy {\n\t\tc.migrateState = true\n\t}\n\n\tif val, ok := os.LookupEnv("NIX_TERRAFORM_PLUGIN_DIR"); ok {\n\t\tinitArgs.PluginPath = append(initArgs.PluginPath, val)\n\t}\n'
    '';

    # Nix 호스트에 존재하지 않는 `/bin/stty` 하드코딩 경로 치환 (vendor 복사 후 실행되므로 vendorHash 무영향)
    postConfigure = ''
      substituteInPlace vendor/github.com/bgentry/speakeasy/speakeasy_unix.go \
        --replace-fail "/bin/stty" "${prev.coreutils}/bin/stty"
    '';

    env.CGO_ENABLED =
      if stdenv.hostPlatform.isDarwin
      then "1"
      else "0";

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
  # Java Tooling & Project Build Tools
  # ---------------------------------------------------------------------------
  #
  # 에디터 도구는 JAVA_HOME=17인 셸에서도 독립적으로 기동해야 한다.
  # jdtls와 같은 프로세스 트리에서 동작하는 formatter, lombok도 Java 25에 묶어
  # 도구별 classpath와 runtime이 조용히 갈라지는 것을 방지한다.
  jdt-language-server = prev.jdt-language-server.override {jdk25 = toolingJdk;};
  google-java-format = prev.google-java-format.override {jre = toolingJdk;};
  lombok = prev.lombok.override {jdk = toolingJdk;};

  # 전역 Gradle은 프로젝트 런타임(Java 17)을 사용하며, 저장소별 gradlew는 자체 버전을 따른다.
  gradle = prev.gradle.override {java = projectJdk;};
  neotest-java-junit-platform-console-standalone = prev.fetchurl {
    url = "https://repo1.maven.org/maven2/org/junit/platform/junit-platform-console-standalone/6.0.3/junit-platform-console-standalone-6.0.3.jar";
    hash = "sha256-O6DWFQr3khShQR+eovvvhk7vaLaMiaF/ZywLib/506I=";
  };

  # ---------------------------------------------------------------------------
  # Node.js Tooling Runtime
  # ---------------------------------------------------------------------------
  #
  # Node 기반 LSP와 formatter는 wrapper 내부의 nodejs-slim까지 함께 사용한다.
  # 선언 버전과 내장 runtime이 어긋나는 것을 막기 위해 `nodejs_24` 단일 계층으로 고정한다.
  # (pnpm은 현재 nixpkgs 구현에서 nodejs override를 지원하지 않으므로 upstream 정의 유지)
  typescript-language-server = prev.typescript-language-server.override {nodejs = prev.nodejs_24;};
  prettier = prev.prettier.override {nodejs = prev.nodejs_24;};
  bash-language-server = prev.bash-language-server.override {nodejs-slim = prev.nodejs-slim_24;};

  # ---------------------------------------------------------------------------
  # Bear (Darwin 빌드 및 테스트 호환성 패치)
  # ---------------------------------------------------------------------------
  #
  # 1. Bear 4.2.3의 process-tree signal 테스트는 Darwin 빌더에서 grandchild PID 기록 전
  #    타임아웃되는 비결정적 실패가 있으므로 해당 테스트만 제외한다.
  # 2. nixpkgs 4.2.3 레시피가 postInstall에서 Linux 공유 라이브러리 확장자(`.so`)를 가정하므로
  #    기존 설치 레이아웃은 유지하되 Darwin의 실제 산출물(`.dylib`)을 선택하도록 치환한다.
  bear = prev.bear.overrideAttrs (old: {
    cargoTestFlags =
      (old.cargoTestFlags or [])
      ++ prev.lib.optionals stdenv.hostPlatform.isDarwin [
        "--"
        "--skip"
        "cases::exit_codes::signal_tears_down_build_process_tree"
      ];
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

  # ---------------------------------------------------------------------------
  # Lua & Python Language Server Overrides
  # ---------------------------------------------------------------------------
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
          propagatedBuildInputs = [luasocket];

          meta = {
            homepage = "https://github.com/pkulchenko/MobDebug";
            description = "Remote debugger for the Lua programming language";
            license.fullName = "MIT/X11";
          };
        }
    ) {};
  });

  # WARNING: python-lsp-server가 현재 nixpkgs의 jedi 버전 상한과 충돌하여 적용한 임시 우회.
  # upstream 제약이 풀리면 제거하는 것이 원칙이다.
  python313Packages = prev.python313Packages.overrideScope (_pyFinal: pyPrev: {
    python-lsp-server = pyPrev.python-lsp-server.overridePythonAttrs (_: {
      pythonRelaxDeps = ["jedi"];
      doCheck = false;
    });
  });
}
