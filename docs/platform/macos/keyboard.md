# macOS Keyboard Customization

This guide covers the Karabiner-Elements configuration included in this repository, which provides Windows/GNOME-style keyboard shortcuts and quick app launching for macOS.

## Table of Contents

- [Overview](#overview)
- [Key Mappings](#key-mappings)
- [Configuration](#configuration)
- [Customization](#customization)
- [Troubleshooting](#troubleshooting)

---

## Overview

This repository includes a comprehensive Karabiner-Elements configuration that:

- **Provides Windows/GNOME-style shortcuts** for better cross-platform consistency
- **Enables quick app launching** via keyboard shortcuts
- **Preserves terminal behavior** by excluding terminal apps from remapping
- **Improves productivity** with intuitive keyboard shortcuts

### Why This Configuration?

If you:
- Switch between macOS and Linux/Windows frequently
- Find macOS default shortcuts unintuitive
- Want consistent keyboard shortcuts across platforms
- Need quick access to frequently used applications

This configuration will significantly improve your workflow.

---

## Key Mappings

### Windows/GNOME-Style Shortcuts

These shortcuts work in **all apps except terminals**, providing familiar keyboard behavior for Linux/Windows users:

#### Text Editing
| Keys | Action | Native macOS Equivalent |
|------|--------|------------------------|
| `Ctrl+C` | Copy | `Cmd+C` |
| `Ctrl+V` | Paste | `Cmd+V` |
| `Ctrl+X` | Cut | `Cmd+X` |
| `Ctrl+A` | Select all | `Cmd+A` |
| `Ctrl+Z` | Undo | `Cmd+Z` |
| `Ctrl+S` | Save | `Cmd+S` |

#### Tab/Window Management
| Keys | Action | Native macOS Equivalent |
|------|--------|------------------------|
| `Ctrl+W` | Close tab/window | `Cmd+W` |
| `Ctrl+T` | New tab | `Cmd+T` |

#### Text Navigation
| Keys | Action | Native macOS Equivalent |
|------|--------|------------------------|
| `Ctrl+←` | Previous word | `Option+←` |
| `Ctrl+→` | Next word | `Option+→` |
| `Ctrl+Backspace` | Delete word backward | `Option+Backspace` |
| `Ctrl+Delete` | Delete word forward | `Option+Delete` |

### App Launcher Shortcuts

Quick access to frequently used applications:

#### Number Key Shortcuts
| Keys | Application |
|------|-------------|
| `Cmd+1` | TickTick |
| `Cmd+2` | Slack |
| `Cmd+3` | Obsidian |
| `Cmd+4` | Google Chrome |
| `Cmd+5` | IntelliJ IDEA |
| `Cmd+6` | GoLand |

#### Option+Letter Shortcuts
| Keys | Application |
|------|-------------|
| `Cmd+Option+T` | WezTerm |
| `Cmd+Option+D` | Docker Desktop |
| `Cmd+Option+M` | YouTube Music |
| `Cmd+Option+C` | Google Chrome |
| `Cmd+Option+I` | IntelliJ IDEA |
| `Cmd+Option+G` | GoLand |

### Special Key Mappings

| Keys | Action | Purpose |
|------|--------|---------|
| `Right Command` | `F18` | For custom shortcuts in other apps |

---

## Configuration

### Configuration Location

The Karabiner configuration is located at:
```
dotfiles/karabiner/karabiner.json
```

When home-manager is applied (via `just install-pckgs`), this file is symlinked to:
```
~/.config/karabiner/karabiner.json
```

### Terminal Exclusions

Windows/GNOME-style shortcuts are **automatically disabled** in terminal applications to preserve their native behavior (e.g., `Ctrl+C` for interrupt).

**Excluded Applications**:
- Terminal.app
- iTerm2
- WezTerm
- Alacritty
- Kitty
- Emacs

This ensures terminal applications maintain their expected keyboard shortcuts without interference.

### Installation

The configuration is automatically installed when you run:
```bash
just install-pckgs
```

Or manually with home-manager:
```bash
home-manager switch --flake .#hm-aarch64-darwin  # Apple Silicon
home-manager switch --flake .#hm-x86_64-darwin   # Intel Mac
```

---

## Customization

### Adding New App Launchers

To add shortcuts for your own applications:

1. **Edit the configuration file**:
   ```bash
   # Edit the dotfiles version (recommended)
   vim dotfiles/karabiner/karabiner.json
   ```

2. **Find the app launcher section** (search for `"description": "App Launcher"`):
   ```json
   {
     "description": "App Launcher: Cmd+7 to YourApp",
     "manipulators": [
       {
         "from": {
           "key_code": "7",
           "modifiers": {
             "mandatory": ["command"]
           }
         },
         "to": [
           {
             "shell_command": "open -a 'YourApp.app'"
           }
         ],
         "type": "basic"
       }
     ]
   }
   ```

3. **Apply the changes**:
   ```bash
   just install-pckgs
   ```

### Modifying Keyboard Shortcuts

To change existing shortcuts:

1. **Locate the rule** you want to modify in `dotfiles/karabiner/karabiner.json`

2. **Modify the key mapping**:
   ```json
   "from": {
     "key_code": "c",  // The key to map from
     "modifiers": {
       "mandatory": ["control"]  // Required modifier keys
     }
   },
   "to": [
     {
       "key_code": "c",  // The key to map to
       "modifiers": ["command"]  // Target modifier keys
     }
   ]
   ```

3. **Apply the changes**:
   ```bash
   just install-pckgs
   ```

### Adding Terminal App Exclusions

To exclude additional terminal applications from remapping:

1. **Find the conditions section** in the rule:
   ```json
   "conditions": [
     {
       "type": "frontmost_application_unless",
       "bundle_identifiers": [
         "^com\\.apple\\.Terminal$",
         "^com\\.googlecode\\.iterm2$",
         "^com\\.github\\.wez\\.wezterm$",
         "^io\\.alacritty$",
         "^net\\.kovidgoyal\\.kitty$",
         "^org\\.gnu\\.Emacs$",
         "^com\\.your\\.terminal$"  // Add your terminal app
       ]
     }
   ]
   ```

2. **Find the bundle identifier** of your app:
   ```bash
   # Get bundle ID of running app
   osascript -e 'id of app "YourTerminal"'
   ```

3. **Apply the changes**:
   ```bash
   just install-pckgs
   ```

---

## Troubleshooting

### Shortcuts Not Working

**Symptom**: Keyboard shortcuts are not being applied

**Solutions**:

1. **Verify Karabiner-Elements is running**:
   ```bash
   # Check if Karabiner is running
   ps aux | grep karabiner
   ```

2. **Check configuration is symlinked**:
   ```bash
   # Verify symlink exists
   ls -la ~/.config/karabiner/karabiner.json

   # Should point to: /nix/store/.../karabiner.json
   ```

3. **Restart Karabiner-Elements**:
   ```bash
   # Via GUI: Karabiner-Elements → Preferences → Misc → Restart

   # Or via command line:
   launchctl kickstart -k gui/$(id -u)/org.pqrs.karabiner.karabiner_console_user_server
   ```

4. **Check permissions**:
   - System Preferences → Security & Privacy → Privacy
   - Ensure Karabiner-Elements has "Input Monitoring" permission

### Shortcuts Work Everywhere Including Terminals

**Symptom**: `Ctrl+C` doesn't interrupt terminal commands

**Cause**: Terminal app not in exclusion list

**Solution**: Add your terminal app to the exclusion list (see [Customization](#adding-terminal-app-exclusions))

### App Launcher Shortcuts Don't Work

**Symptom**: `Cmd+1`, `Cmd+2`, etc. don't launch apps

**Possible Causes & Solutions**:

1. **App not installed at expected path**:
   ```bash
   # Check if app exists
   ls -la /Applications/YourApp.app

   # Update path in karabiner.json if needed
   "shell_command": "open -a '/Applications/YourApp.app'"
   ```

2. **App name changed**:
   ```bash
   # Find correct app name
   ls /Applications/ | grep -i appname

   # Update in karabiner.json
   ```

3. **Conflicting shortcuts**:
   - Check if another app is using the same shortcut
   - System Preferences → Keyboard → Shortcuts
   - Disable conflicting system shortcuts

### Configuration Changes Not Applied

**Symptom**: After editing `dotfiles/karabiner/karabiner.json`, changes don't take effect

**Solution**:
```bash
# Apply configuration
just install-pckgs

# Restart Karabiner-Elements
# Via GUI or:
launchctl kickstart -k gui/$(id -u)/org.pqrs.karabiner.karabiner_console_user_server
```

### Karabiner-Elements Not Installed

**Symptom**: Karabiner-Elements is not installed on your system

**Solution**:

This configuration **only provides the config file**, not the Karabiner-Elements app itself.

Install Karabiner-Elements:
```bash
# Via Homebrew (recommended)
brew install --cask karabiner-elements

# Or download from official website:
# https://karabiner-elements.pqrs.org/
```

Then apply the configuration:
```bash
just install-pckgs
```

---

## Advanced Topics

### Understanding the Configuration Structure

The `karabiner.json` file has this structure:

```json
{
  "global": { /* Global settings */ },
  "profiles": [
    {
      "name": "Default",
      "complex_modifications": {
        "rules": [
          {
            "description": "Rule description",
            "manipulators": [
              {
                "from": { /* Source key */ },
                "to": [ /* Target key(s) */ ],
                "conditions": [ /* When to apply */ ],
                "type": "basic"
              }
            ]
          }
        ]
      }
    }
  ]
}
```

### Key Mapping Examples

#### Simple Key Swap
```json
{
  "from": { "key_code": "caps_lock" },
  "to": [ { "key_code": "escape" } ]
}
```

#### Modifier Remapping
```json
{
  "from": {
    "key_code": "c",
    "modifiers": { "mandatory": ["control"] }
  },
  "to": [
    {
      "key_code": "c",
      "modifiers": ["command"]
    }
  ]
}
```

#### Shell Command Execution
```json
{
  "from": {
    "key_code": "1",
    "modifiers": { "mandatory": ["command"] }
  },
  "to": [
    {
      "shell_command": "open -a 'TickTick.app'"
    }
  ]
}
```

---

## Additional Resources

- [Karabiner-Elements Official Documentation](https://karabiner-elements.pqrs.org/docs/)
- [Karabiner-Elements GitHub](https://github.com/pqrs-org/Karabiner-Elements)
- [macOS Setup Guide](setup.md)
- [Repository Structure](../../reference/repository-structure.md)

---

## See Also

- [macOS Setup Guide](setup.md) - Complete macOS configuration guide
- [Commands Reference](../../guides/commands-reference.md) - All available justfile commands
- [Troubleshooting](../../guides/troubleshooting.md) - General troubleshooting guide
