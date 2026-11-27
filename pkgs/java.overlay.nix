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
}
