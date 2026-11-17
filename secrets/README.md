# secrets/ - encrypted secrets and local key material

This directory keeps SOPS-managed secrets for this Home Manager/Nix setup.

## Directory Structure

```text
secrets/
├── age-key.txt.example   # tracked template only
└── README.md             # this document
```

The previously used encrypted secret file is intentionally not part of the
active configuration. Any archived copy must remain encrypted and must not be
pasted into chat or written into Nix files.

## Age Key

Private age keys are local-only credentials. Keep them ignored by Git.

On a new machine, copy the existing matching identity from `tonys-mac-air` over
Tailscale. The recipe refuses to overwrite a local key and verifies the public
recipient before installing it with mode `0600` in SOPS's platform-default
location (`~/Library/Application Support/sops/age/keys.txt` on macOS):

```bash
just sops-age-key-pull
sops --decrypt <archived-secret-file> >/dev/null
```

If you use an existing age identity, keep this repository's `.sops.yaml`
recipient in sync with that identity's public key.
