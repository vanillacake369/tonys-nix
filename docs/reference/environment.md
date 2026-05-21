# Development Environment Connections

This guide covers setting up and using development environment connections including database SSH tunnels and VPN access.

## Table of Contents

- [Overview](#overview)
- [Environment Variables Setup](#environment-variables-setup)
- [Database Connections](#database-connections)
- [VPN Connections](#vpn-connections)
- [Troubleshooting](#troubleshooting)
- [Security Best Practices](#security-best-practices)

---

## Overview

This repository includes scripts for connecting to development resources that require credentials stored in environment variables.

### Available Connections

- **SSH Tunnels**: Secure database access via bastion hosts
- **VPN**: OpenVPN connections with automatic password handling
- **Automatic Authentication**: expect-based password insertion

### Key Features

- **Gitignored credentials**: `scripts/env.sh` never committed to repository
- **Automatic password handling**: No manual password entry during connections
- **Debug output**: Masked sensitive information in logs
- **Easy setup**: Single environment file for all credentials

---

## Environment Variables Setup

### Creating the Environment File

The `scripts/env.sh` file contains sensitive credentials and is **gitignored for security**.

**One-time setup**:

```bash
# Create scripts/env.sh with your credentials
cat > scripts/env.sh << 'EOF'
#!/bin/bash
# Environment variables for development
# Usage: source scripts/env.sh

# Aquanuri DB connection
export AQUANURI_BASTION_URL="your-bastion-host"
export AQUANURI_BASTION_PW="your-password"
export AQUANURI_BASTION_PORT="3306"
export AQUANURI_TARGET_URL="your-target-host"
export AQUANURI_LOCAL_PORT="3307"

# VPN credentials
export HAMA_VPN_PW="your-vpn-password"
EOF

# Make it executable
chmod +x scripts/env.sh
```

### Environment Variables Reference

| Variable | Purpose | Example |
|----------|---------|---------|
| `AQUANURI_BASTION_URL` | Bastion host IP/hostname | `10.0.13.122` |
| `AQUANURI_BASTION_PW` | SSH password for bastion | `your-secure-password` |
| `AQUANURI_BASTION_PORT` | Remote MySQL port | `3306` |
| `AQUANURI_TARGET_URL` | Target server IP/hostname | `146.56.44.51` |
| `AQUANURI_LOCAL_PORT` | Local port for tunnel | `3307` |
| `HAMA_VPN_PW` | OpenVPN private key password | `your-vpn-password` |

### Loading Environment Variables

Before using any connection scripts, load the environment variables:

```bash
just source-env
```

**What it does**:
- Sources `scripts/env.sh`
- Validates required variables are set
- Shows loaded variables (passwords masked)

**Verification**:
```bash
# Check specific variable (be careful with sensitive data)
echo $AQUANURI_BASTION_URL  # Should show your bastion host

# Verify all variables loaded
just source-env
```

---

## Database Connections

### SSH Tunnel to Development Database

Connect to Aquanuri development database via SSH tunnel:

```bash
# 1. Load credentials
just source-env

# 2. Establish tunnel
just aquanuri-connect

# The tunnel will remain open
# Use another terminal for database connections
```

### How It Works

The `aquanuri-connect` command:
1. Sources environment variables from `scripts/env.sh`
2. Uses `expect` to automate password entry
3. Establishes SSH tunnel: `localhost:3307 → bastion → target:3306`
4. Keeps tunnel open for database connections

### Connecting to the Database

Once the tunnel is established, connect using:

```bash
# Using mysql client
mysql -h 127.0.0.1 -P 3307 -u your_username -p

# Using application connection string
mysql://user:pass@localhost:3307/database_name
```

### Connection Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| Host | `127.0.0.1` or `localhost` | Local machine |
| Port | `3307` | Local port (configurable via `AQUANURI_LOCAL_PORT`) |
| Username | Your DB username | Application-specific |
| Password | Your DB password | Application-specific |

### Debug Output

The script provides debug information:
```bash
[DEBUG] Password (first 3 chars): abc***
[DEBUG] Detected password prompt
[DEBUG] Sent password
```

**Note**: Only first 3 characters are shown for security.

---

## VPN Connections

### OpenVPN Connection

Connect to VPN with automatic password handling:

```bash
# 1. Load credentials
just source-env

# 2. Connect to VPN (default config)
just vpn-connect

# Or use custom config file
just vpn-connect custom-config.ovpn
```

### Default Configuration

**Default config file**: `lonelynight1026.ovpn`

This file should be present in the repository root or specified directory.

### Custom Configuration Files

To use a different OpenVPN configuration:

```bash
just vpn-connect /path/to/your/config.ovpn
```

### How It Works

The `vpn-connect` command:
1. Sources environment variables from `scripts/env.sh`
2. Uses `expect` to handle password prompt
3. Connects using provided `.ovpn` file
4. Automatically enters password when prompted

### Verifying VPN Connection

```bash
# Check IP address (should show VPN IP)
curl ifconfig.me

# Check VPN interface
ifconfig | grep tun

# Ping VPN gateway
ping <vpn-gateway-ip>
```

---

## Troubleshooting

### Environment Variables Not Loaded

**Symptom**: "Required environment variable not set" errors

**Solution**:
```bash
# 1. Verify env file exists
ls -la scripts/env.sh

# 2. Check file permissions
chmod +x scripts/env.sh

# 3. Load variables
just source-env

# 4. Verify specific variable
echo $AQUANURI_BASTION_URL
```

### Password Not Working

**Symptom**: Connection fails despite correct password

**Solutions**:

1. **Verify password in env file**:
   ```bash
   # Edit scripts/env.sh
   vim scripts/env.sh

   # Verify password is correct (no extra spaces)
   export AQUANURI_BASTION_PW="exactly-your-password"
   ```

2. **Check for special characters**:
   - Escape special shell characters if needed
   - Use single quotes for passwords with special chars

3. **Reload environment**:
   ```bash
   just source-env
   ```

### SSH Tunnel Connection Drops

**Symptom**: SSH tunnel disconnects unexpectedly

**Solutions**:

1. **Check network connectivity**:
   ```bash
   ping $AQUANURI_BASTION_URL
   ```

2. **Verify bastion host is accessible**:
   ```bash
   ssh user@$AQUANURI_BASTION_URL
   ```

3. **Check for firewall issues**:
   - Ensure outbound SSH (port 22) is allowed
   - Verify bastion host firewall rules

4. **Add keep-alive to SSH config**:
   ```bash
   # Add to ~/.ssh/config
   Host *
       ServerAliveInterval 60
       ServerAliveCountMax 3
   ```

### VPN Connection Fails

**Symptom**: VPN connection fails or hangs

**Solutions**:

1. **Verify OpenVPN is installed**:
   ```bash
   which openvpn
   # Should show path to openvpn
   ```

2. **Check VPN config file exists**:
   ```bash
   ls -la lonelynight1026.ovpn
   ```

3. **Test manual connection**:
   ```bash
   sudo openvpn lonelynight1026.ovpn
   # Enter password manually to test
   ```

4. **Check VPN server status**:
   - Verify VPN server is accessible
   - Check for maintenance windows

### Debug Output Not Showing

**Symptom**: No debug output from connection scripts

**Solution**:

Check the script files for debug flags:
```bash
# View the aquanuri connection script
cat scripts/aquanuri-dev.sh

# Verify expect debug lines are present
grep "DEBUG" scripts/aquanuri-dev.sh
```

### Permission Denied Errors

**Symptom**: Permission errors when running scripts

**Solutions**:

1. **Make scripts executable**:
   ```bash
   chmod +x scripts/env.sh
   chmod +x scripts/aquanuri-dev.sh
   chmod +x scripts/vpn-connect.sh
   ```

2. **Check sudo requirements**:
   - VPN connections may require sudo
   - Ensure you have sudo privileges

---

## Security Best Practices

### Protecting Credentials

✅ **DO**:
- Keep `scripts/env.sh` gitignored (already configured)
- Use strong, unique passwords
- Rotate credentials regularly
- Limit access to env file: `chmod 600 scripts/env.sh`
- Store backups securely (encrypted)

❌ **DON'T**:
- Commit credentials to git
- Share env file via unsecured channels
- Use same password across multiple services
- Store passwords in plain text elsewhere

### Environment File Permissions

Recommended permissions for security:

```bash
# Restrict access to owner only
chmod 600 scripts/env.sh

# Verify permissions
ls -la scripts/env.sh
# Should show: -rw------- (600)
```

### Password Complexity

**Guidelines**:
- Minimum 12 characters
- Mix of uppercase, lowercase, numbers, symbols
- Avoid dictionary words
- Use password manager for generation

### Rotating Credentials

Regularly update credentials:

```bash
# 1. Edit env file
vim scripts/env.sh

# 2. Update passwords
export AQUANURI_BASTION_PW="new-secure-password"
export HAMA_VPN_PW="new-vpn-password"

# 3. Reload environment
just source-env

# 4. Test connections
just aquanuri-connect
just vpn-connect
```

### Distributing Credentials Securely

When sharing credentials with team members:

**Recommended methods**:
- Encrypted password managers (1Password, LastPass)
- Secure file sharing with encryption
- In-person transfer
- Company secure credential vault

**NOT recommended**:
- Email
- Slack/chat messages
- Unencrypted cloud storage
- Version control systems

---

## Integration with Development Workflow

### Standard Development Session

```bash
# 1. Load credentials
just source-env

# 2. Connect to database
just aquanuri-connect

# 3. In another terminal, work with database
mysql -h 127.0.0.1 -P 3307 -u user -p

# 4. Connect to VPN if needed
just vpn-connect

# 5. Work on your project
# ... development work ...

# 6. Disconnect (Ctrl+C on tunnel terminals)
```

### Automated Setup Script

Create a personal setup script for quick access:

```bash
# Create setup script
cat > ~/dev-setup.sh << 'EOF'
#!/bin/bash
cd ~/dev/tonys-nix

# Load environment
just source-env

# Open tunnel in background
just aquanuri-connect &

# Wait for tunnel
sleep 2

# Connect to VPN
just vpn-connect &

echo "Development environment ready!"
EOF

chmod +x ~/dev-setup.sh
```

---

## Advanced Topics

### Multiple Database Connections

To support multiple databases, extend `scripts/env.sh`:

```bash
# Database 1
export DB1_BASTION_URL="bastion1.example.com"
export DB1_BASTION_PW="password1"
export DB1_LOCAL_PORT="3307"

# Database 2
export DB2_BASTION_URL="bastion2.example.com"
export DB2_BASTION_PW="password2"
export DB2_LOCAL_PORT="3308"
```

Then create additional justfile recipes or scripts for each connection.

### SSH Key-Based Authentication

For better security, use SSH keys instead of passwords:

```bash
# 1. Generate SSH key
ssh-keygen -t ed25519 -C "your-email@example.com"

# 2. Copy to bastion host
ssh-copy-id user@bastion-host

# 3. Update connection script to use key instead of password
```

### VPN Auto-Reconnect

Create a watch script for automatic VPN reconnection:

```bash
#!/bin/bash
while true; do
    if ! ping -c 1 <vpn-gateway-ip> &> /dev/null; then
        echo "VPN down, reconnecting..."
        just source-env
        just vpn-connect
    fi
    sleep 60
done
```

---

## See Also

- [Commands Reference](../guides/commands-reference.md) - All available commands
- [Troubleshooting Guide](../guides/troubleshooting.md) - General troubleshooting
- [Repository Structure](../reference/repository-structure.md) - Project organization
- [Development Workflow Guide](../guides/development-workflow.md) - Recommended workflows
