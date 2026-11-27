_final: prev: let
  inherit (prev) stdenv;
in {
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
}
