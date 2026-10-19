# Harness remediation worklist

Scope: Phase 0–2 defects from the 2026-10-18 audit. Preserve the original audit
as historical evidence. No deployment, provider activation, commit, or external
mutation is part of verification.

1. Fail-closed hook payloads, pre-tool file guard placement, safe launcher default.
2. Explicit decision policy input; retain mandatory approval precedence.
3. MCP policy shape and role consistency; reject mutation without an execution adapter.
4. Actual result requirement, completion state and Git snapshot validation.
5. Persistent BLOCKED retry state and state-file concurrency protection.
6. Memory namespace, decoded limits and promotion validation.
7. Verified traceability references must exist.
8. Provider SSoT exports and reviewer permission projections; distinguish static
   verification from installed-provider execution tests.
9. Run original audit, focused regression, hooks, guard and lint; update checklist
   with remaining runtime verification gaps, never treating declarations as enforcement.

Red evidence: `python3 docs/agent/testing/harness-audit-2026-10-18.py` exited 1:
12 checks, 3 passed, 9 failed before implementation in this remediation turn.
Existing tests using incomplete policy/evidence or nonexistent verified artifacts
will be updated to valid fixtures; rejection assertions remain and new negative
cases cover the stricter contract. These fixture changes are required by the PRD.

Implemented: all nine original reproductions; Claude pre-tool/file/MCP gates;
safe sandbox defaults; actual verification recorder; snapshot-bound completion;
repo-persistent lifecycle baseline and Claude SessionStart/Stop adapter; memory
limits/path safety; retry BLOCKED persistence; operation registry concurrency and
duplicate-fingerprint rejection; provider import exports and unsupported MCP omission.

The second remediation wave added provider lifecycle/retry adapters, scoped
external approval and independent test-review receipts, PRD/status cross-checks,
MCP outcome audit records, and memory entry locking/PII rejection. Remaining
mandatory Phase 0–2 work is tracked explicitly in
`../architecture/harness-reverification-2026-10-18.md`: native runtime checks
and a credential boundary stronger than same-user filesystem permissions. The
test suite does not by itself prove full Phase completion.
