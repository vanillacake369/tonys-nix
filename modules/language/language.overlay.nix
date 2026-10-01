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
  # - projectJdk : 최신 jdtls 실행에 Java 21 이상이 필요하므로 추가
  # - toolingJdk : 회사 프로젝트는 toolingJdk 기준으로 빌드
  # 둘을 하나로 합치면 프로젝트 호환성 또는
  # 에디터 진단 중 하나가 깨지므로
  # 별도의 두 값을 따로두어 각각의 관심사를 처리하도록 한다.
  projectJdk = prev.zulu17;
  toolingJdk = prev.zulu21;
in {
  # Home Manager도 같은 정책을 소비하도록 패키지 집합에 역할 이름을 공개한다.
  # projectJdk는 셸의 기본 JDK이고 toolingJdk는 도구 래퍼 내부 전용이다.
  javaProjectJdk = projectJdk;
  javaToolingJdk = toolingJdk;

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

  # ---------------------------------------------------------------------------
  # Java tooling runtime
  # ---------------------------------------------------------------------------
  #
  # 에디터 도구는 JAVA_HOME=17인 셸에서도 독립적으로 기동해야 한다.
  # jdtls와 같은 프로세스 트리에서 동작하는 formatter와 lombok도 21에 묶어
  # 도구별 classpath와 runtime이 조용히 갈라지는 것을 막는다.
  jdt-language-server = prev.jdt-language-server.override {jdk = toolingJdk;};
  google-java-format = prev.google-java-format.override {jre = toolingJdk;};
  lombok = prev.lombok.override {jdk = toolingJdk;};

  # ---------------------------------------------------------------------------
  # Java project runtime
  # ---------------------------------------------------------------------------
  #
  # 전역 gradle은 회사 프로젝트와 같은 Java 17에서 실행한다. 저장소에
  # gradlew가 있으면 wrapper가 Gradle 버전을 고르고, 이 JDK 정책은 유지된다.
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
