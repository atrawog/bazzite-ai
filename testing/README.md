# Testing Utilities for ujust Commands

This directory contains utilities for testing ujust recipe changes locally without rebuilding the entire container image.

## Quick Start

```bash
# Method 1: Test wrapper (safest, no system modifications)
./testing/ujust-test <recipe>

# Example: Test our devcontainers-cli fix
./testing/ujust-test install-devcontainers-cli
```

## Available Files

- **`ujust-test`** - Test wrapper script that uses repository justfiles
- **`test-master.justfile`** - Test justfile that imports repository recipes
- **`apply-usroverlay.sh`** - Helper for rpm-ostree usroverlay method
- **`README.md`** - This file

## Testing Methods

### Method 1: Test Wrapper (Recommended)

**Use when:** You want to quickly test recipe logic without system modifications

```bash
# List available recipes
./testing/ujust-test --list

# Run a specific recipe
./testing/ujust-test install-devcontainers-cli

# Test with arguments
./testing/ujust-test install-dev-tools
```

**Pros:**
- No system modifications
- No reboot required
- Safe for experimentation

**Cons:**
- May not have full system dependencies
- Some recipes might behave differently

### Method 2: rpm-ostree usroverlay

**Use when:** You need full environment testing with actual system integration

```bash
# Apply temporary overlay (lost on reboot)
sudo ./testing/apply-usroverlay.sh --transient

# Test with real ujust command
ujust install-devcontainers-cli

# Reboot to undo
sudo systemctl reboot
```

**Pros:**
- Full system integration
- Tests with real ujust command
- Same environment as production

**Cons:**
- Requires root access
- Requires reboot to fully undo
- More invasive

## Example Workflow

### Testing the devcontainers-cli Fix

1. **Edit the recipe** in `system_files/usr/share/ublue-os/just/97-bazzite-ai-dev.just`

2. **Quick test with wrapper:**
   ```bash
   ./testing/ujust-test install-devcontainers-cli
   ```

3. **If it works, test with usroverlay for full validation:**
   ```bash
   sudo ./testing/apply-usroverlay.sh --transient
   ujust install-devcontainers-cli
   ```

4. **Commit if successful:**
   ```bash
   git add system_files/usr/share/ublue-os/just/97-bazzite-ai-dev.just
   git commit -m "Fix: devcontainers-cli verification check"
   ```

5. **Reboot to restore immutability:**
   ```bash
   sudo systemctl reboot
   ```

## Troubleshooting

### ujust-test not finding recipes

Check that test-master.justfile imports are correct:
```bash
cat testing/test-master.justfile | grep import
```

### usroverlay script fails

Make sure you're running with sudo:
```bash
sudo ./testing/apply-usroverlay.sh --transient
```

### Changes not taking effect

After usroverlay, verify files were copied:
```bash
ls -l /usr/share/ublue-os/just/9*.just
```

## Safety Notes

- ⚠️ **usroverlay requires reboot to fully undo** - even with --transient
- 💾 Backups are automatically created in `/var/tmp/bazzite-ai-just-backup-*`
- 🔄 Always test with wrapper first before using usroverlay
- 📝 Document your changes before applying to production

## See Also

- Main documentation: `../CLAUDE.md` - Section "Testing ujust Command Changes Locally"
- Comprehensive test report: `../DEVCONTAINERS-CLI-FIX.md`
- Test script for post-rebuild: `../test-devcontainers-cli-fix.sh`
