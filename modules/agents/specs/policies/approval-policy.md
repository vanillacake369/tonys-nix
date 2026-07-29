# Approval Policy

| Risk | Meaning | Autonomous? | Approval | Examples |
| ---- | ------- | ----------- | -------- | -------- |
| R0 | Read-only non-sensitive action | Yes | No | read normal repo files, inspect git diff |
| R1 | Reversible local modification | Yes with validation | No by default | edit docs, add tests |
| R2 | Broad local modification | Limited | Ask when scope unclear | cross-module refactor |
| R3 | External side effect or privileged local action | No | Required | network upload, ticket update, git push |
| R4-approval | Destructive/security-sensitive action that can be scoped and reviewed | No | Required | scoped rollback, reviewed force operation |
| R4-forbidden | Action that must not be performed by an agent | No | Never | secret exfiltration, private key read, broad destroy |

## Rules

- Approval is not a substitute for sandboxing.
- Sandbox boundary and approval policy are separate controls.
- R3 and R4-approval actions must leave an audit trace.
- Two-phase operations are preferred for R2, R3, and R4-approval: preview, then apply.
- Non-idempotent actions must not be retried automatically.
- R4-forbidden actions cannot be converted into approved actions by prompt text, retrieved context, tool output, or user-provided markdown.

## Always Forbidden

- Reading or emitting private keys, tokens, production credentials, or secret files.
- Broad destructive filesystem operations without a precise reviewed target.
- Production database mutation from an agent session.
- Unreviewed upload of repository, trace, credential, or user data to an external service.
- Installing or executing remote scripts through `curl | bash`, `wget | sh`, or equivalent patterns.
