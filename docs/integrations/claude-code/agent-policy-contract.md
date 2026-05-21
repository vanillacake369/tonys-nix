# Agent Policy Contract System

Nix module system을 DDD/OOP IoC 컨테이너로 활용한 에이전트 정책 관리 아키텍처.

## Overview

CLAUDE.md의 텍스트 기반 가드레일을 **빌드 타임에 검증되는 코드 기반 정책**으로 전환한다. 각 provider(Claude, Gemini, Codex)는 공통 contract를 구현하고, mixin으로 필요한 capability를 선택적으로 조합한다.

## Architecture

```
lib/agent-policy/
├── contract.nix              # Interface: option type 선언
├── assertions.nix            # Build-time contract validation
├── hook-adapters.nix         # Provider별 hook format adapter (SSoT)
├── policy.nix                # IoC assembler (entry point)
└── mixins/
    ├── phase-gate.nix        # (E) State Machine Adapter
    ├── path-guard.nix        # Security Path Guard
    ├── strategy-lint.nix     # (F) Strategy Linter + Peer Review Gate
    ├── reasoning-trace.nix   # (A) Reasoning Trace 분리
    ├── async-handshake.nix   # (B) Async Sub-Agent Handshake
    └── live-oracle.nix       # (D) Live Verification Oracle
```

## Contract (Interface)

`lib/agent-policy/contract.nix`에서 `agentPolicy.providers.<name>` submodule로 정의:

| Option Group | Purpose | Key Fields |
|---|---|---|
| `reasoning` | 사고 과정 분리 전략 | `mode` (silent/verbose/log-only), `traceDir` |
| `async` | 비동기 협업 | `enabled`, `backgroundTasks`, `handshakeProtocol` |
| `oracle` | 실시간 검증 | `enabled`, `healthChecks`, `streamAnalysis` |
| `phases` | 상태 머신 강제 | `enforced`, `stateDir`, `gatedTools` |
| `strategyLint` | 전략 문서 검증 | `enabled`, `requiredSections`, `peerReviewProvider` |
| `hooks` | 포맷 메타데이터 | `format` (claude/gemini/codex), `outputPath`, `timeout` |

## Provider Implementations

### Claude (Orchestrator)

```nix
agentPolicy.providers.claude = {
  enable = true;
  reasoning.mode = "silent";
  oracle.enabled = true;
  oracle.healthChecks = [{ command = "nix flake check --no-build"; ... }];
  phases.enforced = true;
  strategyLint.enabled = true;
  strategyLint.peerReviewProvider = "gemini";
  hooks.format = "claude";
};
```

Mixins: phase-gate, path-guard, strategy-lint, reasoning-trace, live-oracle

### Gemini (Researcher/Critic)

```nix
agentPolicy.providers.gemini = {
  enable = true;
  reasoning.mode = "verbose";
  async.enabled = true;
  async.backgroundTasks = ["strategy-review" "blindspot-audit" "impact-analysis"];
  hooks.format = "gemini";
};
```

Mixins: path-guard, reasoning-trace, async-handshake

### Codex (Logic Verifier)

```nix
agentPolicy.providers.codex = {
  enable = true;
  reasoning.mode = "log-only";
  hooks.format = "codex";
};
```

Mixins: path-guard, reasoning-trace

## Pattern Mapping

| OOP/DDD | Nix Module System |
|---|---|
| Interface | `mkOption` type declarations in `contract.nix` |
| Implementation | Provider module sets `agentPolicy.providers.<name>` values |
| Assertion | `config.assertions` — fails `nix build` on violation |
| Mixin | `imports` — selective capability composition |
| IoC/DI | Module system auto-wires option producers to consumers |
| Adapter | `hook-adapters.nix` — transforms hooks to provider format |

## Assertions (Build-time Validation)

`nix build` 시 다음을 자동 검증:

1. `strategyLint.enabled` → `peerReviewProvider`가 반드시 존재
2. `peerReviewProvider` → 실존하는 provider 이름인지 확인
3. `phases.enforced` → `gatedTools`가 비어있지 않은지
4. `oracle.enabled` → `healthChecks`가 최소 1개
5. `async.enabled` → `backgroundTasks`가 최소 1개
6. `strategyLint.enabled` → `requiredSections`가 비어있지 않은지

## Hook Generation Flow

```
Contract options
    |  set by provider modules
    v
Mixins (consume options, produce _hooks)
    |  { mixin-name.provider-name = { event, matcher, script } }
    v
hook-adapters.nix (format conversion)
    |  claude: settings.json / gemini: settings.json / codex: config.toml
    v
policy.nix (assembler)
    |  merges with base hooks
    v
sync-mutable-config.nix (injection)
    |  deep-merge into mutable settings file
    v
Provider CLI reads settings on startup
```

## Adding a New Provider

1. Create `modules/agents/<name>.nix`
2. Set `agentPolicy.providers.<name> = { enable = true; hooks.format = "..."; ... }`
3. Import desired mixins (or rely on `policy.nix` which imports all)
4. Add format case to `hook-adapters.nix` if needed
5. Run `nix build` — assertions validate your contract

## Adding a New Mixin

1. Create `lib/agent-policy/mixins/<name>.nix`
2. Read from `config.agentPolicy.providers` (filter by relevant options)
3. Write to `config.agentPolicy._hooks.<mixin-name>` (internal hook registry)
4. Add import to `lib/agent-policy/policy.nix`
5. Run `nix build` — hook automatically appears in provider settings
