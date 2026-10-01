{
  description = "Multi-platform flake (NixOS, WSL, Linux, MacOS)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # NOTE:
    # neovim-unwrapped는 editor overlay에서 직접 치환되는 runtime core다.
    # nixos-unstable을 그대로 따라가면 plugin ABI, treesitter parser, LSP
    # 동작이 한 번에 움직인다. 이 SHA는 의도적인 release valve이므로 bump는
    # editor smoke test와 함께 URL을 바꾸는 작업으로 취급한다.
    nixpkgs-neovim.url = "github:nixos/nixpkgs/d86da6ff1a3db2d1e667684c6f34c21896767b3e";
  };

  outputs = {
    nixpkgs,
    nixpkgs-neovim,
    home-manager,
    llm-agents,
    rust-overlay,
    ...
  }: let
    inherit (nixpkgs) lib;
    # NOTE: macOS는 Apple Silicon만 지원한다. nixpkgs 26.11부터 x86_64-darwin은 평가 불가.
    supportedSystems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin"];
    homeActivationCheckSystems = ["x86_64-linux" "aarch64-darwin"];
    forAllSystems = lib.genAttrs supportedSystems;

    # NOTE:
    # flake.nix는 repo 전체의 조립 루트다. discovery 규칙이나
    # compatibility entry 생성 규칙을 여기서 직접 펼치면 flake가 곧
    # 정책 저장소가 되어 다시 비대해진다. 복잡한 변환은 lib/에 두고,
    # 이 파일은 입력을 연결하는 조합 계층으로만 유지한다.
    overlays =
      (import ./lib/collect-flake-overlays.nix {
        inherit lib llm-agents nixpkgs-neovim rust-overlay;
      })
      ./modules;

    userProfiles = (import ./lib/collect-user-profiles.nix {inherit lib;}) ./user;

    builders = import ./lib/mk-home-config.nix {
      inherit nixpkgs home-manager overlays;
      homeManagerModules = [./home.nix];
    };
    mkImages = import ./lib/mk-images.nix {
      inherit lib nixpkgs;
      configModules = [./configuration.nix];
    };

    hostnames = ["tony"];
    collectTests = (import ./lib/collect-tests.nix {inherit lib;}) ./tests;
  in rec {
    nixosConfigurations = lib.genAttrs hostnames (_:
      nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        inherit ((builders.mkSystem "x86_64-linux")) pkgs;
        modules = [./configuration.nix];
      });

    homeConfigurations = (import ./lib/mk-home-entries.nix {inherit lib;}) {
      inherit supportedSystems userProfiles;
      inherit (builders) mkHomeConfig;
    };

    packages = forAllSystems mkImages;

    checks = forAllSystems (system: let
      inherit (builders.mkSystem system) pkgs;
      homeConfigs =
        lib.mapAttrs (
          profileName: _: homeConfigurations."hm-${profileName}-${system}"
        )
        userProfiles;
      collectChecks = (import ./lib/collect-checks.nix {inherit lib;}) ./tests;
      tests = collectTests {inherit lib;};
    in
      collectChecks {
        inherit lib pkgs homeConfigs tests;
      }
      // lib.optionalAttrs (builtins.elem system homeActivationCheckSystems) {
        home-activations = pkgs.linkFarm "home-activations-${system}" (
          lib.mapAttrsToList (profileName: homeConfig: {
            name = profileName;
            path = homeConfig.activationPackage;
          })
          homeConfigs
        );
      });
  };
}
