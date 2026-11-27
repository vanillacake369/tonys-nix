_final: prev: {
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
}
