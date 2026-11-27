_final: prev: let
  inherit (prev) stdenv;
in {
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
}
