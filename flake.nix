{
  description = "Multi-platform flake (NixOS, WSL, Linux, MacOS)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
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
    # Temurin 보안 릴리스가 기본 nixpkgs에 반영될 때까지 Java 패키지만 고정한다.
    nixpkgs-java.url = "github:nixos/nixpkgs/2786a2a72088ecf32aea5b3ec52099e6a7cff78f";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-neovim,
    nixpkgs-java,
    nix-darwin,
    home-manager,
    rust-overlay,
    treefmt-nix,
    ...
  }: let
    inherit (nixpkgs) lib;
    # NOTE: macOS는 Apple Silicon만 지원한다. nixpkgs 26.11부터 x86_64-darwin은 평가 불가.
    supportedSystems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin"];
    homeActivationCheckSystems = ["x86_64-linux" "aarch64-darwin"];
    forAllSystems = lib.genAttrs supportedSystems;

    # Overlay 순서는 package API다. Rust를 먼저, Neovim runtime pin을 마지막에 둔다.
    overlays = [
      (import rust-overlay)
      (import ./pkgs/bear.overlay.nix)
      (import ./pkgs/java.overlay.nix {inherit nixpkgs-java;})
      (import ./pkgs/jetendard.overlay.nix)
      (import ./pkgs/lua-debugger.overlay.nix)
      (import ./pkgs/node-tooling.overlay.nix)
      (import ./pkgs/python-lsp.overlay.nix)
      (import ./pkgs/terraform.overlay.nix)
      (import ./pkgs/wayland-ime.overlay.nix)
      (import ./pkgs/zellij.overlay.nix)
      (_final: prev: {
        neovim-unwrapped =
          nixpkgs-neovim.legacyPackages.${prev.stdenv.hostPlatform.system}.neovim-unwrapped;
      })
    ];

    userProfiles = (import ./lib/collect-user-profiles.nix {inherit lib;}) ./profiles;

    builders = import ./lib/mk-home-config.nix {
      inherit nixpkgs home-manager overlays;
      homeManagerModules = (import ./lib/discover-modules.nix {inherit lib;} ./modules).homeManager;
    };
    mkImages = import ./lib/mk-images.nix {
      inherit lib nixpkgs;
      configModules = [./nodes/tony.nixos.nix];
    };

    localDarwinConfig = builtins.getEnv "TONYS_NIX_DARWIN_LOCAL_CONFIG";
    localDarwinModule = builtins.getEnv "TONYS_NIX_DARWIN_LOCAL_MODULE";
    collectTests = (import ./lib/collect-tests.nix {inherit lib;}) ./tests;
    treefmtEval =
      forAllSystems (system:
        treefmt-nix.lib.evalModule nixpkgs.legacyPackages.${system} ./treefmt.nix);
  in rec {
    formatter = forAllSystems (system: treefmtEval.${system}.config.build.wrapper);

    nixosConfigurations.tony = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      inherit ((builders.mkSystem "x86_64-linux")) pkgs;
      modules = [./nodes/tony.nixos.nix];
    };

    darwinConfigurations."tonys-mac" = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules =
        [
          {nixpkgs.overlays = overlays;}
          ./nodes/tonys-mac.darwin.nix
        ]
        ++ lib.optional (localDarwinConfig == "tonys-mac" && localDarwinModule != "") (/. + localDarwinModule);
    };

    apps.aarch64-darwin.darwin-rebuild = {
      type = "app";
      program = "${nix-darwin.packages.aarch64-darwin.darwin-rebuild}/bin/darwin-rebuild";
    };

    homeConfigurations = (import ./lib/mk-home-entries.nix {inherit lib;}) {
      inherit supportedSystems userProfiles;
      inherit (builders) mkHomeConfig;
    };

    packages = forAllSystems mkImages;

    checks = forAllSystems (system: let
      inherit (builders.mkSystem system) pkgs;
      tests = collectTests {inherit lib;};
      homeConfigs =
        lib.mapAttrs (
          profileName: _: homeConfigurations."hm-${profileName}-${system}"
        )
        userProfiles;
    in
      {
        guard-tests = pkgs.runCommand "guard-tests" {} ''
          echo '${builtins.toJSON tests.summary}' > "$out"
        '';
        formatting = treefmtEval.${system}.config.build.check self;
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
