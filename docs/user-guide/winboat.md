---
title: WinBoat - Windows App Support
---

# WinBoat Guide - Running Windows Apps on Bazzite AI

Run Windows applications on Bazzite AI with seamless integration using containerized Windows VM technology.

## Overview

```{admonition} What is WinBoat?
:class: tip

WinBoat enables running Windows applications on Bazzite AI with seamless integration. Windows apps appear as native Linux windows using containerized Windows VM technology.
```

### Architecture

```{list-table}
:header-rows: 1
:widths: 30 70

* - Component
  - Description
* - **Windows Environment**
  - Full Windows VM in Docker container
* - **Display Protocol**
  - FreeRDP 3.x with RemoteApp
* - **Integration**
  - WinBoat Guest Server communicates with Linux host
* - **Storage**
  - Home directory mounted in Windows for file sharing
```

## First-Time Setup

### Step 1: Launch WinBoat

```bash
# Start WinBoat GUI
winboat
```

### Step 2: Initial Configuration

The setup wizard will guide you through:

::::{grid} 1 1 2 2
:gutter: 2

:::{grid-item-card} Windows Container
Download Windows container image (~10GB)
:::

:::{grid-item-card} Resource Allocation
Configure RAM and CPU allocation
:::

:::{grid-item-card} Network Setup
Configure networking and connectivity
:::

:::{grid-item-card} Display Settings
Set up RemoteApp display protocol
:::

::::

**Recommended Settings:**

```{list-table}
:header-rows: 1
:widths: 30 40 30

* - Resource
  - Minimum
  - Recommended
* - RAM
  - 4GB
  - 8GB
* - CPU Cores
  - 2
  - 4+
* - Storage
  - 32GB
  - 64GB+
```

### Step 3: Container Initialization

```{warning}
First launch takes 15-30 minutes!
```

The initialization process:

1. Downloads Windows container image
2. Initializes Windows environment
3. Configures RemoteApp server
4. Sets up file sharing

```{tip}
Grab a coffee while the container initializes - this is a one-time operation!
```

## Usage

### Launch Windows Apps

::::{grid} 1
:gutter: 2

:::{grid-item-card}
:class-header: bg-light

**Step-by-step:**

1. Open WinBoat interface
2. Browse available Windows applications
3. Click to launch as native Linux window
4. Apps appear in taskbar like native apps

:::

::::

### Access Full Windows Desktop

When you need the complete Windows experience:

```{dropdown} Opening full desktop
:open:

1. Click "Open Desktop" in WinBoat
2. Full Windows desktop opens in window
3. Install new apps, configure settings
4. Close when done - apps remain available
```

### File Management

#### Home Directory Sharing

```{admonition} Automatic mounting
:class: note

Your Linux home directory is automatically mounted in Windows as the `Z:\` drive.
```

**Features:**
- Bidirectional file access
- No manual copying needed
- Seamless integration

**Example:**

```powershell
# In Windows
cd Z:\Documents
notepad my-file.txt
```

```bash
# In Linux
cat ~/Documents/my-file.txt
# Same file!
```

#### Windows-Native Files

- Stored in container volume
- Persists across reboots
- Backed up with container

## Troubleshooting

### WinBoat Won't Start

::::{dropdown} Check Docker

```bash
# Verify Docker is running
sudo systemctl status docker

# Check Docker permissions
docker ps
```

::::

::::{dropdown} Check Resources

```bash
# View available RAM
free -h

# Check disk space
df -h /var/lib/docker
```

::::

### Windows Container Issues

::::{dropdown} Reset Container

**Steps:**

1. Stop WinBoat
2. Remove container from WinBoat interface
3. Re-run setup wizard

```bash
# Or manually via Docker
docker stop <winboat-container>
docker rm <winboat-container>
```

::::

### Display Problems

::::{dropdown} Verify FreeRDP

```bash
# Check FreeRDP version
xfreerdp --version
# Should show 3.x.x
```

::::

::::{dropdown} Audio Issues

```bash
# Check PulseAudio/PipeWire
pactl info
```

::::

### Performance Optimization

::::{dropdown} Allocate More Resources

1. Open WinBoat settings
2. Increase RAM allocation
3. Add more CPU cores
4. Restart Windows container

```{tip}
Most performance issues can be solved by allocating more RAM and CPU cores.
```

::::

::::{dropdown} Enable Hardware Acceleration
:color: warning

**Experimental feature:**

- Requires NVIDIA GPU
- Configure in WinBoat settings
- Pass GPU to container (beta)

```{warning}
GPU passthrough for WinBoat is experimental and may not work reliably.
```

::::

## Limitations

### Known Restrictions

```{list-table}
:header-rows: 1
:widths: 40 60

* - Limitation
  - Details
* - **No Podman Support**
  - Requires Docker CE (pre-installed on Bazzite AI)
* - **No Rootless**
  - Must use rootful Docker (default in Bazzite AI)
* - **Beta Software**
  - Expect occasional issues
* - **Resource Intensive**
  - Requires significant RAM/CPU
* - **No GPU Passthrough**
  - Limited 3D acceleration (beta feature)
```

### Incompatible Software

```{admonition} Some Windows apps may not work
:class: warning

- Games with anti-cheat (kernel-level)
- Apps requiring direct hardware access
- Some DRM-protected software
```

## Advanced Usage

### Custom Windows ISO

Use your own Windows installation:

::::{dropdown} Using custom ISO

1. Download Windows ISO
2. Configure in WinBoat settings
3. Specify ISO path
4. Run custom installation

```bash
# Example
# 1. Download Windows 11 ISO
# 2. Open WinBoat Settings → Advanced
# 3. Set ISO path: /path/to/Windows11.iso
# 4. Click "Reinstall with Custom ISO"
```

::::

### Container Management

#### View Containers

```bash
docker ps -a | grep winboat
```

#### Container Logs

```bash
docker logs <container-id>
```

#### Backup Container

```bash
docker commit <container-id> winboat-backup

# Save to file
docker save winboat-backup > winboat-backup.tar

# Restore later
docker load < winboat-backup.tar
```

## Security Considerations

### Isolation

```{admonition} Container-based isolation
:class: tip

- Windows runs in container (isolated from host)
- Network access controlled by Docker
- File access limited to mounted directories
```

### Recommendations

::::{grid} 1 1 2 2
:gutter: 2

:::{grid-item-card} ✅ Do
- Keep Windows container updated
- Use Windows Defender (included)
- Review file sharing permissions
- Regular backups
:::

:::{grid-item-card} ❌ Don't
- Don't disable container isolation
- Don't expose all directories
- Don't run untrusted executables
- Don't disable Windows updates
:::

::::

## Getting Help

::::{grid} 1 1 2 2
:gutter: 2

:::{grid-item-card} 🐛 WinBoat Issues
Official WinBoat project

[GitHub Issues](https://github.com/TibixDev/winboat/issues)
:::

:::{grid-item-card} 📚 Bazzite AI Integration
Bazzite AI-specific issues

[GitHub Issues](https://github.com/atrawog/bazzite-ai/issues)
:::

::::

## Related Documentation

```{seealso}
- {doc}`containers/usage` - Linux container development
- {doc}`containers/gpu-setup` - GPU configuration
- [WinBoat GitHub](https://github.com/TibixDev/winboat) - Official project page
```
