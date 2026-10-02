# secrets/ - encrypted secrets and local key material

This directory keeps SOPS-managed secrets for this Home Manager/Nix setup.

## Directory Structure

```text
secrets/
├── mcp.yaml              # SOPS-encrypted MCP secrets, safe to commit
├── age-key.txt.example   # tracked template only
└── README.md             # this document
```

## Secret File

Edit the encrypted secret file with:

```bash
sops secrets/mcp.yaml
```

Expected TickTick entry:

```yaml
ticktick:
  mcp_token: <token managed by sops>
```

Do not paste the token into chat or write it into Nix files. The next integration
step should read this secret at activation/runtime and expose it as
`TICKTICK_MCP_TOKEN` without putting the value in the Nix store.

Atlassian's non-interactive MCP fallback expects these encrypted entries:

```yaml
atlassian:
  user_email: <API token owner>
  api_token: <token managed by sops>
```

Interactive use should prefer `codex mcp login atlassian`. The launcher derives
the Basic authorization header in memory only when both entries exist.

## Age Key

Private age keys are local-only credentials. Keep them ignored by Git.

On a new machine, copy the existing matching identity from `tonys-mac-air` over
Tailscale. The recipe refuses to overwrite a local key and verifies the public
recipient before installing it with mode `0600` in SOPS's platform-default
location (`~/Library/Application Support/sops/age/keys.txt` on macOS):

```bash
just sops-age-key-pull
sops --decrypt secrets/mcp.yaml >/dev/null
```

Because the recipe uses SOPS's default location, direct commands such as
`sops secrets/mcp.yaml` work without an environment variable.
`agent-secret-env` also supports overriding the identity for a single process
with `AGENT_SOPS_AGE_KEY_FILE` or the standard `SOPS_AGE_KEY_FILE` variable.

If you use an existing age identity, keep this repository's `.sops.yaml`
recipient in sync with that identity's public key.
