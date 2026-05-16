# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Operational Guardrails

### Hard Rules (위반 시 즉시 중단)

1. **추론으로 넘겨짚지 말 것.** 확인되지 않은 사실은 "미확인"으로 명시. "~일 수 있습니다", "아마도" 금지.
2. **사용자 동의 없이 리팩토링/구조 변경 금지.**
3. **테스트 검증 없이 "완료" 보고 금지.** 핵심 기능 + 엣지케이스 테스트 통과 필수.
4. **통합 확인 없이 "완료" 보고 금지.** 실제 빌드/실행으로 동작 확인.
5. **Heavy tool call (연속 10+ 또는 대규모 탐색) 전 범위/비용 보고 필수.**
6. **.env 읽기 전 확인 필수. git add 시 .gitignore 누락 경고.**
7. **보안 의심 사항 무시 금지.** 발견 즉시 보고.
8. **커밋 규칙 엄수.** `type(scope): description` 형식, SRP 준수.
9. **지정된 workflow phase를 임의로 건너뛰지 말 것.**
10. **nvim LSP/lint/formatter가 적용되는 프로젝트에서 이를 무시하고 파일 작성 금지.**
11. **애매한 표현 지양.** 실제 확인된 사실과 이슈를 근거로 정확하게 구현/분석.

### Workflow Checkpoints

순서를 준수하며, 각 phase 완료 후 다음으로 진행:

```
Phase 1: 문제 정의 → 애매한 부분 질의 → 사용자 승인
Phase 2: 연구 & 분석 → 관련 지식 수집 → 핵심 원인 + 원리 정리 → 공유
Phase 3: 전략 제시 → 선택지 + 트레이드오프 나열 → 사용자 선택 대기
Phase 4: 설계 & 테스트 케이스 → TDD 케이스 + 엣지케이스 정의 → 사용자 승인
Phase 5: 구현 → lint/format 확인 포함 → 테스트 통과 확인
Phase 6: 통합 검증 → 실제 동작 확인 → 보고
```

단순 작업(파일 수정 1-2개, 명확한 지시)은 Phase 5-6만 수행.

### Auto-Allow (확인 없이 수행 가능)

- 코드베이스 읽기/검색
- 테스트 실행/확인
- 서버 실행 및 동작 확인
- Playwright 실행
- 연구/이슈/논문 검색
- 워크플로우/개선안 **제시** (실행은 승인 후)

### Error Recovery Protocol

- 빌드/테스트 실패 시: `git stash` → 원인 분석 → `[ROLLBACK]` 태그로 보고
- 3회 연속 같은 접근 실패 시: 즉시 중단, 대안 제시
- 복구 후 자동 보고에 rollback 사실 포함

### Tone & Reference Policy

- 모든 기술적 주장에 출처 명시 (공식 문서 URL, GitHub issue, RFC, 논문 등)
- 출처를 찾을 수 없는 주장은 "출처 미확인 — 검증 필요"로 표기
- hedging 표현("~일 수 있습니다", "아마도", "대체로") 대신 확인 상태를 명시
- 톤: 간결하고 사실 중심. 불필요한 수식어 배제.

### Token Efficiency

- 같은 파일 반복 읽기 금지 (한 번 읽은 내용은 세션 내 기억)
- 불필요한 전체 파일 출력 금지 (변경 부분만)
- 서브에이전트에게 동일 작업 중복 위임 금지
- 긴 출력 예상 시 요약 → 상세 확장 패턴 사용

## Project Overview

This is a personal Nix configuration repository using flakes and home-manager for managing multi-platform development environments (NixOS, WSL, macOS). The configuration provides a comprehensive development setup with tools for Go, Java, Kubernetes, Docker, and modern CLI utilities.

## Essential Commands

### Primary Workflow (Recommended)

```bash
just install-all      # Complete installation pipeline
just install-pckgs    # Install/update packages (auto-detects system)
just smart-clean      # Intelligent SSD-optimized cleanup
```

### Quick Reference

**Installation**:
- `just install-nix` - Install Nix package manager
- `just install-home-manager` - Install home-manager
- `just install-uidmap` - Install uidmap for containers (Linux only)

**Maintenance**:
- `just gc-status` - Check garbage collection status
- `just force-clean` - Force cleanup (manual override)
- `just performance-test` - Comprehensive system analysis

**Development**:
- `just source-env` - Load development credentials
- `just aquanuri-connect` - SSH tunnel to database
- `just vpn-connect` - Connect to VPN

**Images**:
- `just build-image iso` - Build bootable ISO
- `just build-all-images` - Build all formats

📖 **For complete command reference**, see [Commands Reference Guide](docs/guides/commands-reference.md) covering:
- Detailed command descriptions and usage
- System-specific configurations
- Manual home-manager operations
- Environment variables reference
- Command combinations and workflows

## Repository Structure

### Core Configuration Files
- **flake.nix**: Main flake definition with multi-platform support (NixOS, WSL, macOS)
- **home.nix**: Core home-manager configuration importing all modules
- **configuration.nix**: NixOS system configuration (GNOME, services, security)
- **hardware-configuration.nix**: (gitignored) NixOS hardware-specific settings (stored in /etc/nixos/)
- **justfile**: Build automation with environment detection
- **limjihoon-user.nix**: Primary user configuration
- **nixos-user.nix**: NixOS-specific user settings

### Module Organization (`modules/`)
- **apps.nix**: Desktop applications (browsers, editors, productivity tools)
- **infra.nix**: Infrastructure and DevOps tools (Docker, Kubernetes, cloud CLI)
- **language.nix**: Programming language support (Go, Java, Node.js, Python)
- **nvim.nix**: Neovim configuration and plugin management
- **shell.nix**: Shell utilities (git, fzf, ripgrep, modern CLI tools)
- **zsh.nix**: Zsh configuration with oh-my-zsh and powerlevel10k

### Dotfiles Management (`dotfiles/`)
Configuration files are symlinked from dotfiles directory:
- **lazyvim/**: Complete LazyVim Neovim configuration with language support
- **zellij/**: Terminal multiplexer configuration and layouts
- **nix/** and **nixpkgs/**: Nix-specific configuration files
- **autohotkey/**: Windows automation scripts (for WSL environments)
- **screen/**: Screen session configurations
- **karabiner/**: macOS keyboard remapping with productivity shortcuts
- **claude/**: Claude Code configuration with automatic sync
  - **commands/**: Custom slash commands
  - **agents/**: Custom AI agents
  - **settings.json**: Project-level settings (auto-synced to `~/.claude/settings.json`)
  - **CLAUDE.md**: Project instructions
  - **permissions.json**: Global permissions and MCP servers (auto-synced to `~/.claude.json`)

### Library Functions (`lib/`)
- **builders.nix**: Custom Nix builders and utility functions

### Multi-Platform Support
The flake provides architecture-aware configurations:
- **hm-x86_64-linux**: Standard Linux (64-bit)
- **hm-aarch64-linux**: ARM64 Linux
- **hm-wsl-x86_64-linux**: Windows Subsystem for Linux
- **hm-x86_64-darwin**: Intel macOS
- **hm-aarch64-darwin**: Apple Silicon macOS
- **nixos**: Full NixOS system configuration for host systems

### Key Features
- Multi-platform support with automatic environment detection
- Rootless Podman with Docker compatibility and podman-compose support
- Korean input support (ibus-hangul) for desktop environments
- GNOME desktop environment with Wayland optimizations
- SSH hardening with Google Authenticator 2FA
- Comprehensive development environment for cloud-native workflows
- Modern shell environment with extensive CLI tooling
- nix-ld support for running dynamically linked executables

## Environment Detection

The justfile automatically detects your system and architecture:

### Operating System Detection
- **WSL**: Detected via `/proc/version` containing "Microsoft" 
- **NixOS**: Detected by existence of `/etc/nixos` directory
- **macOS**: Detected via `uname -s` returning "Darwin"
- **Standard Linux**: Default fallback for other Linux distributions

### Architecture Detection  
- **x86_64**: Intel/AMD 64-bit systems
- **aarch64**: ARM64 systems (Apple Silicon, ARM servers)
- Auto-selects appropriate flake configuration based on detected platform

## Development Workflow

### Standard Development Process
1. **Modify configurations**: Edit relevant files in `modules/` or core config files
2. **Test changes**: Use dry-run to validate without applying changes
3. **Apply changes**: Run `just install-pckgs` for automatic platform detection
4. **Smart cleanup**: Run `just smart-clean` for intelligent SSD-optimized cleanup (or use `just install-all` which includes smart cleanup)

### Multi-Host Deployment
When deploying to multiple NixOS machines:

#### Initial Setup on New NixOS Host
```bash
# 1. Clone repository
git clone <repository-url>
cd tonys-nix

# 2. Generate hardware configuration for this machine
sudo nixos-generate-config --show-hardware-config > /etc/nixos/hardware-configuration.nix

# 3. Apply configuration
just install-all
```

#### Updating Existing Hosts
```bash
# Pull latest changes
git pull

# Apply updates (hardware-configuration.nix in /etc/nixos/ remains unchanged)
just install-pckgs
```

> **Important**: `hardware-configuration.nix` is excluded from git and stored in `/etc/nixos/` because it contains machine-specific settings (disk UUIDs, kernel modules, CPU types) that differ between hosts. The flake uses `--impure` flag to access this system-level configuration.

### Testing and Validation
```bash
just install-all                                           # Test complete installation pipeline
just performance-test                                      # Analyze Nix performance and configuration
nix flake check                                           # Validate flake syntax and structure
home-manager switch --flake .#hm-x86_64-linux --dry-run  # Test Linux config without applying
home-manager switch --flake .#hm-wsl-x86_64-linux --dry-run # Test WSL config without applying
home-manager switch --flake .#hm-aarch64-darwin --dry-run # Test Apple Silicon config without applying
```

## Claude Code Configuration Management

### Automatic Configuration Sync

This repository uses a **hybrid approach** to manage Claude Code configuration:
- **Static files** (commands, agents, skills, CLAUDE.md) are symlinked directly
- **Dynamic files** are automatically synced during home-manager activation:
  - `permissions.json` → `~/.claude.json` (merged)
  - `settings.json` → `~/.claude/settings.json` (merged)
- **Runtime data** in `~/.claude.json` (projects, tipsHistory, etc.) is preserved

### How It Works

When you run `just install-pckgs`, home-manager:
1. **Symlinks static files** to `~/.claude/`:
   - `commands/`, `agents/`, `skills/`, `CLAUDE.md`
2. **Executes activation scripts** that:
   - Merge `permissions.json` into `~/.claude.json` (preserves runtime data)
   - Merge/copy `settings.json` to `~/.claude/settings.json` (creates writable copy)
   - Create timestamped backups before modification

### Configuration Files

#### `dotfiles/claude/permissions.json`
Contains only permissions and MCP servers you want to version control:
- **permissions**: Tool access rules (Read, WebFetch, Bash, etc.)
- **mcpServers**: MCP server configurations (npay, kakaopay, context7, etc.)

```json
{
  "permissions": {
    "allow": [
      "Read(*)",
      "WebFetch(*)",
      "WebSearch(*)",
      "Bash(git commit:*)",
      ...
    ]
  },
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp@latest"]
    },
    ...
  }
}
```

#### `dotfiles/claude/settings.json`
Contains Claude Code project-level settings:
- Editor preferences, UI settings, feature flags, etc.
- Synced to `~/.claude/settings.json` as a writable copy

#### `~/.claude.json`
Your local configuration file that contains:
- Settings from `permissions.json` (auto-synced)
- Runtime data (numStartups, tipsHistory, projects, etc.)
- Machine-specific state

#### `~/.claude/settings.json`
Your local settings file that contains:
- Settings from `dotfiles/claude/settings.json` (auto-synced)
- User modifications (preserved during sync)

### Benefits

✅ **Version Control**: Share permissions and MCP servers across machines
✅ **Preserve Runtime Data**: Project history and settings stay intact
✅ **Automatic Sync**: No manual steps needed
✅ **Safe Updates**: Automatic backups before each sync
✅ **Multi-Machine**: Same configuration on all your devices

### Modifying Configuration

#### Add/Remove Permissions
Edit `dotfiles/claude/permissions.json`:
```json
{
  "permissions": {
    "allow": [
      "Read(*)",
      "Glob(*)",
      "YourNewTool(*)"
    ]
  }
}
```

Then apply:
```bash
just install-pckgs
```

#### Add/Remove MCP Servers
Edit `dotfiles/claude/permissions.json`:
```json
{
  "mcpServers": {
    "new-server": {
      "command": "npx",
      "args": ["-y", "@example/mcp-server"]
    }
  }
}
```

Then apply:
```bash
just install-pckgs
```

#### Modify Settings
Edit `dotfiles/claude/settings.json`:
```json
{
  "editor.fontSize": 14,
  "ui.theme": "dark"
}
```

Then apply:
```bash
just install-pckgs
```

### Implementation Details

The sync is powered by:
- **Nix `home.activation`**: Runs activation scripts after symlinks are created
- **jq**: Merges JSON files (`.[0] * .[1]` operator)
- **sponge** (moreutils): Safely writes to files
- **lib.hm.dag.entryAfter**: Ensures proper execution order

Two separate activation scripts:
- `syncClaudePermissions`: Merges `permissions.json` → `~/.claude.json`
- `syncClaudeSettings`: Merges/copies `settings.json` → `~/.claude/settings.json`

See `home.nix:55-112` for the implementation.

## Troubleshooting

### Quick Diagnostics

```bash
just performance-test  # Comprehensive system analysis
just gc-status         # Check garbage collection status
nix flake check        # Validate configuration
```

### Common Issues (Quick Reference)

**NixOS Configuration**:
- Hardware config missing → `sudo nixos-generate-config --show-hardware-config > /etc/nixos/hardware-configuration.nix`
- Slow builds → `just smart-clean` then `just performance-test`
- Build failures → `nix flake check`

**Containers & Performance**:
- Podman/Minikube failures → `just enable-shared-mount` and enable cgroup v2
- Large store size → `just force-clean` or `nix store optimise`

**Development Environment**:
- Missing env vars → Create `scripts/env.sh` and run `just source-env`
- Connection issues → Verify credentials and network

📖 **For comprehensive troubleshooting**, see [Troubleshooting Guide](docs/guides/troubleshooting.md) with detailed solutions for:
- NixOS configuration issues
- Performance and store management
- Container and virtualization problems
- Development environment setup
- Build and installation errors

### SSD Optimization

This configuration includes comprehensive SSD optimization to extend drive lifespan and improve performance.

#### Automatic Optimizations (Already Enabled)

- **Store auto-optimization**: Deduplication reduces store size by 20-40%
- **Optimized build settings**: Uses all CPU cores for faster builds
- **Smart GC**: Only runs when needed (size > 10GB or > 14 days) - **reduces SSD wear by 80-90%**
- **Binary caches**: Reduces local builds by 80-90%
- **Journal limits**: Logs capped at 500MB with monthly rotation

#### Quick Commands

```bash
just gc-status         # Check GC status and recommendations
just smart-clean       # Intelligent cleanup (auto-decision)
just force-clean       # Force cleanup (manual override)
just performance-test  # Comprehensive analysis
```

#### Manual Hardware Optimization

Add to `/etc/nixos/hardware-configuration.nix` (per-machine):
```nix
fileSystems."/" = {
  # ... existing config ...
  options = [ "noatime" "discard=async" ];
};
```

- **`noatime`**: Prevents access time updates → reduces writes
- **`discard=async`**: Enables TRIM → better wear leveling

📖 **For complete optimization guide**, see [SSD Optimization Guide](docs/guides/ssd-optimization.md) covering:
- Detailed automatic optimizations explanation
- Smart GC system deep dive
- Manual hardware optimizations
- SSD health monitoring
- Performance analysis
- Best practices and troubleshooting

### Debugging Commands
```bash
# Check system detection
echo "OS: $(just OS_TYPE), Arch: $(just SYSTEM_ARCH)"

# Performance and configuration analysis
just performance-test           # Comprehensive Nix performance analysis

# Hardware configuration validation
sudo nixos-generate-config --show-hardware-config  # Preview hardware config
ls -la /etc/nixos/hardware-configuration.nix       # Check if hardware config exists

# Validate flake configurations
nix flake show                  # List all available configurations
nix eval .#homeConfigurations   # Show home-manager configurations

# Test specific configurations
home-manager build --flake .#hm-x86_64-linux    # Build without applying
nix build .#homeConfigurations.hm-x86_64-linux.activationPackage  # Direct nix build
```

### Clean Installation (Reset)
```bash
just clear-all        # Remove home-manager completely
just remove-configs   # Remove all dotfiles and configurations
just install-all      # Fresh installation from scratch
```

## Image Generation

### Quick Start

Create bootable ISOs and VM images from your NixOS configuration:

```bash
just list-image-formats    # Show available formats
just build-image iso        # Build bootable ISO
just build-image virtualbox # Build VirtualBox OVA
just build-all-images       # Build all formats
```

### Supported Formats

- **ISO**: Bootable installation media
- **VirtualBox OVA**: VirtualBox virtualization
- **VMware VMDK**: VMware virtualization
- **QEMU qcow2**: KVM/libvirt, cloud deployments

### Use Cases

- Installation media for NixOS
- Virtual machine images for development/testing
- Cloud deployment images
- Consistent environment distribution

📖 **For detailed documentation**, see [Image Generation Guide](docs/guides/image-generation.md) covering:
- Complete format reference and architecture support
- Advanced usage and direct nix commands
- Use case examples (installation media, VMs, cloud deployment)
- Comprehensive troubleshooting and debugging
- Performance optimization tips

## Development Environment Setup

### Quick Setup

This repository includes scripts for connecting to development resources (databases, VPN) with automatic password handling.

**One-time setup**:
```bash
# 1. Create credentials file (gitignored)
cat > scripts/env.sh << 'EOF'
#!/bin/bash
export AQUANURI_BASTION_URL="your-bastion-host"
export AQUANURI_BASTION_PW="your-password"
export HAMA_VPN_PW="your-vpn-password"
# ... other credentials ...
EOF

# 2. Load and use
just source-env          # Load credentials
just aquanuri-connect    # SSH tunnel to database
just vpn-connect         # Connect to VPN
```

### Standard Development Session

```bash
just source-env          # Load credentials
just aquanuri-connect    # Connect to database (in background)
# ... work in another terminal ...
just vpn-connect         # Connect to VPN if needed
```

📖 **For complete setup guide**, see [Development Connections Guide](docs/integrations/development-connections.md) covering:
- Detailed environment variables reference
- Database connection setup
- VPN configuration
- Troubleshooting connection issues
- Security best practices
- Advanced topics (multiple databases, SSH keys, auto-reconnect)

## macOS Keyboard Customization

### Quick Overview

Karabiner-Elements configuration providing Windows/GNOME-style shortcuts and quick app launching for macOS.

**Windows/GNOME Shortcuts** (all apps except terminals):
- Text editing: `Ctrl+C/V/X/A/Z/S` → Copy, paste, cut, select all, undo, save
- Tab management: `Ctrl+T/W` → New/close tab
- Word navigation: `Ctrl+←/→` → Move by word

**Quick App Launching**:
- `Cmd+1-6` → TickTick, Slack, Obsidian, Chrome, IntelliJ, GoLand
- `Cmd+Option+T/D/M/C/I/G` → WezTerm, Docker, Music, Chrome, IntelliJ, GoLand

**Terminal Behavior**: Terminal apps (Terminal.app, iTerm2, WezTerm, etc.) automatically excluded to preserve native shortcuts.

📖 **For complete documentation**, see [macOS Keyboard Guide](docs/platform/macos/keyboard.md) covering:
- Complete key mapping reference
- Customization guide (adding apps, modifying shortcuts)
- Terminal app exclusions
- Troubleshooting and advanced topics
- Configuration file structure

## Claude Code Integration

### Quick Overview

Optimized **Claude Code slash commands** for Nix development workflows with automatic configuration sync.

### Available Commands

| Command | Purpose | Example |
|---------|---------|---------|
| `/solve` | Universal problem solver | `/solve "Permission denied when running just install-pckgs"` |
| `/enhance` | Code and system improvements | `/enhance "Optimize justfile GC system"` |
| `/scaffold` | Generate working skeleton code (KISS) | `/scaffold "Need backup system for Nix configs"` |
| `/debug` | Systematic debugging | `/debug "Home-manager fails on ARM64 Linux"` |
| `/commit` | Smart git commit | `/commit "Add SSD optimization features"` |
| `/documentify` | Documentation generation | `/documentify "Generate docs for smart GC system"` |

### Key Features

- **Project-aware solutions**: Follow repository patterns and multi-platform architecture
- **Automatic config sync**: Permissions and MCP servers synced across machines via home-manager
- **Structured output**: Analysis → Options → Recommendation → Implementation
- **Quality assurance**: Testing strategies, risk assessment, rollback procedures

### Example Workflow

```bash
/solve "Add Rust development tools to language.nix"  # Get implementation plan
# Apply recommended solution
just install-pckgs                                    # Test changes
/debug "New tool causing build failures"             # If issues arise
/enhance "Optimize new tool integration"             # Improve implementation
```

### Best Practices

1. **Be specific** - Include exact error messages and file references
2. **Mention constraints** - Specify limitations (time, compatibility, resources)
3. **Follow up** - Use commands in sequence for complex problems
4. **Reference context** - Mention relevant files, modules, or components

📖 **For complete documentation**, see [Claude Code Integration Guide](docs/integrations/claude-code/overview.md) covering:
- Detailed command reference with usage examples
- Configuration management and automatic sync
- Command design philosophy
- Integration with development workflow
- MCP server configuration
