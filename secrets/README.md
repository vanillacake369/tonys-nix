# secrets/ - encrypted secrets and local key material

This directory keeps SOPS-managed secrets for this Home Manager/Nix setup.

## Directory Structure

```text
secrets/
├── secrets.yaml          # SOPS-encrypted secrets, safe to commit
├── database.yaml         # SOPS-encrypted native YAML source
├── age-key.txt.example   # tracked template only
└── README.md             # this document
```

## Secret File

Edit the encrypted secret file with:

```bash
sops secrets/secrets.yaml
```

Expected TickTick entry:

```yaml
ticktick:
  mcp_token: <token managed by sops>
```

Do not paste the token into chat or write it into Nix files. The next integration
step should read this secret at activation/runtime and expose it as
`TICKTICK_MCP_TOKEN` without putting the value in the Nix store.

`database.yaml` is the encrypted, native YAML source of truth for
`~/.config/database/databases.toml`. Edit its `production` and `development`
mappings with `sops secrets/database.yaml`. Home Manager decrypts the document,
renders it as TOML, and atomically installs it with mode `0600`; plaintext never
enters the Nix store. Because every activation replaces the runtime file, do not
make persistent edits directly in `~/.config/database/databases.toml`.

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
sops --decrypt secrets/secrets.yaml >/dev/null
```

Because the recipe uses SOPS's default location, direct commands such as
`sops secrets/secrets.yaml` work without an environment variable.
`agent-secret-env` also supports overriding the identity for a single process
with `AGENT_SOPS_AGE_KEY_FILE` or the standard `SOPS_AGE_KEY_FILE` variable.

If you use an existing age identity, keep this repository's `.sops.yaml`
recipient in sync with that identity's public key.
