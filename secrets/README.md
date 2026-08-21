# secrets/ - encrypted secrets and local key material

This directory keeps SOPS-managed secrets for this Home Manager/Nix setup.

## Directory Structure

```text
secrets/
├── secrets.yaml          # SOPS-encrypted secrets, safe to commit
├── age-key.txt           # local age private key, never commit
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

## Age Key

Private age keys are local-only credentials. Keep them ignored by Git.

```bash
age-keygen -o secrets/age-key.txt
```

If you use an existing age identity, keep this repository's `.sops.yaml`
recipient in sync with that identity's public key.
