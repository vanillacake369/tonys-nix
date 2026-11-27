_final: prev: {
  # WARNING: python-lsp-server가 현재 nixpkgs의 jedi 버전 상한과 충돌하여 적용한 임시 우회.
  # upstream 제약이 풀리면 제거하는 것이 원칙이다.
  python313Packages = prev.python313Packages.overrideScope (_pyFinal: pyPrev: {
    python-lsp-server = pyPrev.python-lsp-server.overridePythonAttrs (_: {
      pythonRelaxDeps = ["jedi"];
      doCheck = false;
    });
  });
}
