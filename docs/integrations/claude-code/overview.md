# Claude Code Integration

This repository includes comprehensive Claude Code integration with optimized slash commands, automatic configuration sync, and project-aware assistance.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Available Slash Commands](#available-slash-commands)
- [Configuration Management](#configuration-management)
- [Command Design Philosophy](#command-design-philosophy)
- [Best Practices](#best-practices)
- [Additional Resources](#additional-resources)

---

## Overview

Claude Code is Anthropic's official CLI for Claude, providing an interactive development experience. This repository enhances Claude Code with:

- **Custom slash commands** tailored for Nix development workflows
- **Automatic configuration sync** across machines
- **Project-aware solutions** that follow repository patterns
- **MCP server integrations** for enhanced capabilities

---

## Features

### ✨ Custom Slash Commands

Optimized commands for common development tasks:
- `/solve` - Universal problem solver
- `/enhance` - Code and system improvements
- `/scaffold` - Generate working skeleton code (KISS approach)
- `/debug` - Systematic debugging
- `/commit` - Smart git commit operations
- `/documentify` - Documentation generation
- `/forget-all` - Context reset

### 🔄 Automatic Configuration Sync

Configuration is automatically synced across machines via home-manager:
- **Static files** (commands, agents, CLAUDE.md) symlinked directly
- **Dynamic settings** (permissions, MCP servers) merged into `~/.claude.json`
- **Runtime data** preserved during sync
- **Automatic backups** before modifications

### 🎯 Project-Aware Solutions

All slash commands:
- Follow existing code patterns and conventions
- Respect multi-platform architecture
- Consider performance implications
- Maintain compatibility with tooling ecosystem

---

## Available Slash Commands

### `/solve` - Universal Problem Solver

Analyze and provide optimal solutions for any issue, bug, or requirement.

**Usage Examples**:
```bash
/solve "Getting permission denied when running just install-pckgs"
/solve "Need to add support for a new architecture in the flake"
/solve "Nix build is consuming too much disk space"
```

**Output Structure**:
- Problem analysis with root cause identification
- 3-5 solution options with trade-offs
- Recommended solution considering project patterns
- Detailed implementation plan with validation strategy

---

### `/enhance` - Code and System Improvements

Improve existing code or systems with optimized solutions and safe migration strategies.

**Usage Examples**:
```bash
/enhance "The justfile install-pckgs command is becoming complex with platform detection"
/enhance "Home-manager module organization could be more maintainable"
/enhance "Performance optimization for Nix store operations"
```

**Output Structure**:
- Current state assessment with improvement opportunities
- Enhancement options with impact/effort analysis
- Recommended approach with project guidelines compliance
- Phased implementation strategy with rollback plan

---

### `/scaffold` - Skeleton Code Generation (KISS)

Generate working skeleton code from requirements following the KISS (Keep It Simple, Stupid) principle.

**Usage Examples**:
```bash
/scaffold "Need a backup system for Nix configurations that can restore previous states"
/scaffold "Create a new module for development database connections"
/scaffold "Design a testing framework for Nix flake configurations"
```

**Output Structure**:
- Brief description of what we're building
- Minimal file structure
- Working code that can run immediately
- Simple instructions to get started
- 2-3 next steps to enhance further

**Note**: This command follows KISS principles - it creates the simplest working implementation without complex architectural analysis or multiple options. Start simple, optimize later.

---

### `/debug` - Systematic Debugging

Debug specific issues with systematic root cause analysis and prevention strategies.

**Usage Examples**:
```bash
/debug "Home-manager fails with unclear dependency errors only on ARM64 Linux"
/debug "Podman containers won't start after system update"
/debug "SSH tunnel connection drops unexpectedly during development work"
```

**Output Structure**:
- Issue reproduction steps and investigation process
- Systematic hypothesis testing with evidence
- Multiple fix strategies (quick vs proper solutions)
- Prevention measures and monitoring recommendations

---

### `/commit` - Smart Git Commit

Generate appropriate commit messages and handle git operations intelligently.

**Usage**:
```bash
/commit "Add SSD optimization features"
```

Claude will:
- Analyze staged changes
- Generate appropriate commit message
- Follow repository commit style
- Handle git operations safely

---

### `/documentify` - Documentation Generation

Generate comprehensive documentation from code and configuration files.

**Usage**:
```bash
/documentify "Generate documentation for the smart GC system"
```

---

### `/forget-all` - Context Reset

Clear conversation context while preserving important project information.

**Usage**:
```bash
/forget-all
```

---

## Configuration Management

### Automatic Configuration Sync

This repository uses a **hybrid approach** to manage Claude Code configuration:

**What Gets Synced**:
- Static files (commands, agents, CLAUDE.md) → symlinked to `~/.claude/`
- Dynamic settings (permissions, mcpServers) → merged into `~/.claude.json`

**What Gets Preserved**:
- Runtime data (projects, tipsHistory, etc.)
- Machine-specific state
- User preferences

### How It Works

When you run `just install-pckgs`, home-manager:

1. **Copies static files** to `~/.claude/`
2. **Executes activation script** that:
   - Reads your existing `~/.claude.json`
   - Merges `dotfiles/claude/config-overlay.json` into it
   - Preserves all runtime data
   - Creates timestamped backup before modification

### Configuration Files

#### `dotfiles/claude/config-overlay.json`

Contains only the settings you want to version control:
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
    "kakaopay": { ... },
    "npay-payments": { ... }
  }
}
```

#### `~/.claude.json`

Your local configuration file that contains:
- Settings from `config-overlay.json` (auto-synced)
- Runtime data (numStartups, tipsHistory, projects)
- Machine-specific state

### Benefits

✅ **Version Control**: Share permissions and MCP servers across machines
✅ **Preserve Runtime Data**: Project history and settings stay intact
✅ **Automatic Sync**: No manual steps needed
✅ **Safe Updates**: Automatic backups before each sync
✅ **Multi-Machine**: Same configuration on all your devices

### Modifying Configuration

#### Add/Remove Permissions

1. Edit `dotfiles/claude/config-overlay.json`:
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

2. Apply changes:
   ```bash
   just install-pckgs
   ```

#### Add/Remove MCP Servers

1. Edit `dotfiles/claude/config-overlay.json`:
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

2. Apply changes:
   ```bash
   just install-pckgs
   ```

### Implementation Details

The sync is powered by:
- **Nix `home.activation`**: Runs after symlinks are created
- **jq**: Merges JSON files (`.[0] * .[1]` operator)
- **sponge** (moreutils): Safely writes to files
- **lib.hm.dag.entryAfter**: Ensures proper execution order

See `home.nix:47-72` for the implementation.

---

## Command Design Philosophy

### Integration Over Innovation

Commands are designed to:
- Follow existing code patterns and conventions
- Respect established boundaries and responsibilities
- Consider performance implications (SSD optimization, binary caches)
- Maintain compatibility with current tooling ecosystem

### Clarity and Actionability

Every command follows a consistent pattern:
1. **Analysis**: Understand the problem/requirement in project context
2. **Options**: Present multiple approaches with clear trade-offs
3. **Recommendation**: Choose optimal solution with detailed justification
4. **Implementation**: Provide actionable steps with validation strategies

### Quality Assurance

Commands include:
- Testing and validation approaches
- Risk assessment for each recommended approach
- Rollback procedures for system changes
- Performance impact considerations

---

## Best Practices

### 1. Be Specific

Provide detailed context about your issue or requirement:

```bash
# ❌ Too vague
/solve "Fix the build"

# ✅ Specific
/solve "Home-manager build fails with 'option does not exist' error for services.journald.settings on aarch64-linux"
```

### 2. Include Error Messages

When debugging, include exact error text and conditions:

```bash
/debug "Getting error 'Failed to create /init.scope control group: Permission denied' when running minikube with podman driver on WSL2"
```

### 3. Mention Constraints

Specify any limitations (time, compatibility, resources):

```bash
/enhance "Optimize justfile GC system to reduce SSD wear without requiring bc dependency"
```

### 4. Reference Context

Mention relevant files, modules, or system components:

```bash
/solve "Need to add Rust development tools to language.nix following the existing Go setup pattern"
```

### 5. Follow Up

Use commands in sequence for complex problems:

```bash
# Step 1: Get solution
/solve "Add support for new development tool in language.nix"

# Step 2: Apply and test
just install-pckgs

# Step 3: Debug if issues arise
/debug "New tool causing build failures"

# Step 4: Improve implementation
/enhance "Optimize the new tool integration for better performance"
```

---

## Integration with Development Workflow

### Example Workflow

```bash
# 1. Problem Analysis
/solve "Add support for new development tool in language.nix"

# 2. Apply recommended solution
# ... make changes ...
just install-pckgs

# 3. Test changes
just performance-test

# 4. Debug if issues arise
/debug "New tool causing build failures"

# 5. Fix issues
# ... apply fixes ...
just install-pckgs

# 6. Improve implementation
/enhance "Optimize the new tool integration for better performance"

# 7. Commit changes
/commit "Add new development tool with optimizations"
```

### Quick Reference

| Task | Command | Purpose |
|------|---------|---------|
| Solve problem | `/solve` | Get implementation plan |
| Improve code | `/enhance` | Optimize existing implementation |
| Generate code | `/scaffold` | Create working skeleton (KISS) |
| Debug issue | `/debug` | Systematic troubleshooting |
| Commit changes | `/commit` | Smart git operations |
| Generate docs | `/documentify` | Create documentation |
| Reset context | `/forget-all` | Clear conversation history |

---

## Additional Resources

### Related Documentation

- [Slash Commands Reference](slash-commands.md) - Detailed command documentation
- [Configuration Sync Guide](config-sync.md) - Deep dive into configuration management
- [MCP Servers Guide](mcp-servers.md) - MCP server configuration and usage
- [Development Workflow Guide](../../guides/development-workflow.md)

### Command Files Location

Slash commands are stored in `dotfiles/claude/commands/`:
- `solve.md` - Universal problem solving
- `enhance.md` - Code and system improvements
- `scaffold.md` - Architecture and skeleton generation
- `debug.md` - Systematic debugging and troubleshooting
- `commit.md` - Smart git commit operations
- `documentify.md` - Documentation generation
- `forget-all.md` - Context reset functionality

### External Resources

- [Claude Code Documentation](https://claude.com/claude-code)
- [Anthropic AI Documentation](https://docs.anthropic.com/)
- [MCP Protocol Specification](https://modelcontextprotocol.io/)

---

## See Also

- [Commands Reference](../../guides/commands-reference.md) - All justfile commands
- [Troubleshooting Guide](../../guides/troubleshooting.md) - Common issues and solutions
- [Repository Structure](../../reference/repository-structure.md) - Project organization
