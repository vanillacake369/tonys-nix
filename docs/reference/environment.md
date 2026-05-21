# Environment Variables

## Justfile Variables

These variables are set automatically by the justfile at runtime:

| Variable | Description | Example |
|---|---|---|
| `HOSTNAME` | System hostname | `tonys-mac` |
| `OS_TYPE` | Detected OS | `darwin`, `nixos`, `wsl`, `linux` |
| `SYSTEM_ARCH` | System architecture | `aarch64-darwin`, `x86_64-linux` |
| `GC_MIN_INTERVAL_DAYS` | Minimum days between GC runs | `3` |
| `GC_MAX_INTERVAL_DAYS` | Maximum days before forced GC | `14` |
| `GC_DELETE_OLDER_THAN` | GC retention period in days | `3` |

## AI Provider Environment

The `CLI_PROXY_URL` variable is set in Claude Code's `settings.json`:

```
"env": {
  "CLI_PROXY_URL": "http://127.0.0.1:4001"
}
```

This points to the cli-proxy-api unified auth proxy. See [Agents > Orchestration](../agents/overview.md) for details.
