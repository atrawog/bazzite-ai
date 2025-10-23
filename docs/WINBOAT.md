# WinBoat Guide - Running Windows Apps on Bazzite AI

## Overview

WinBoat enables running Windows applications on bazzite-ai with seamless integration. Windows apps appear as native Linux windows using containerized Windows VM technology.

## Architecture

- **Windows Environment**: Full Windows VM in Docker container
- **Display Protocol**: FreeRDP 3.x with RemoteApp
- **Integration**: WinBoat Guest Server communicates with Linux host
- **Storage**: Home directory mounted in Windows for file sharing

## First-Time Setup

### 1. Launch WinBoat

```bash
# Start WinBoat GUI
winboat
```

### 2. Initial Configuration

The setup wizard will guide you through:
- Windows container download (~10GB)
- Resource allocation (RAM, CPU)
- Network configuration
- Display settings

**Recommended Settings:**
- RAM: 4GB minimum, 8GB recommended
- CPU: 2 cores minimum, 4+ recommended
- Storage: 32GB minimum

### 3. Container Initialization

First launch downloads and configures Windows:
- Downloads Windows container image
- Initializes Windows environment
- Configures RemoteApp server
- Sets up file sharing

**This takes 15-30 minutes on first run.**

## Usage

### Launch Windows Apps

1. Open WinBoat interface
2. Browse available Windows applications
3. Click to launch as native Linux window
4. Apps appear in taskbar like native apps

### Access Full Windows Desktop

When you need the complete Windows experience:
1. Click "Open Desktop" in WinBoat
2. Full Windows desktop opens in window
3. Install new apps, configure settings
4. Close when done - apps remain available

### File Management

**Home Directory Sharing:**
- Your Linux home directory is mounted in Windows
- Path in Windows: `Z:\` drive
- Bidirectional file access
- No manual copying needed

**Windows-Native Files:**
- Stored in container volume
- Persists across reboots
- Backed up with container

## Troubleshooting

### WinBoat Won't Start

**Check Docker:**
```bash
# Verify Docker is running
sudo systemctl status docker

# Check Docker permissions
docker ps
```

**Check Resources:**
```bash
# View available RAM
free -h

# Check disk space
df -h /var/lib/docker
```

### Windows Container Issues

**Reset Container:**
```bash
# Stop WinBoat
# Remove container from WinBoat interface
# Re-run setup wizard
```

### Display Problems

**Verify FreeRDP:**
```bash
# Check FreeRDP version
xfreerdp --version
# Should show 3.x.x
```

**Audio Issues:**
```bash
# Check PulseAudio/PipeWire
pactl info
```

### Performance Optimization

**Allocate More Resources:**
1. Open WinBoat settings
2. Increase RAM allocation
3. Add more CPU cores
4. Restart Windows container

**Enable Hardware Acceleration:**
- Requires NVIDIA GPU
- Configure in WinBoat settings
- Pass GPU to container (experimental)

## Limitations

### Known Restrictions

- **No Podman Support**: Requires Docker CE (pre-installed)
- **No Rootless**: Must use rootful Docker (default in bazzite-ai)
- **Beta Software**: Expect occasional issues
- **Resource Intensive**: Requires significant RAM/CPU
- **No GPU Passthrough**: Limited 3D acceleration (beta feature)

### Incompatible Software

Some Windows apps may not work:
- Games with anti-cheat (kernel-level)
- Apps requiring direct hardware access
- Some DRM-protected software

## Advanced Usage

### Custom Windows ISO

Use your own Windows installation:
1. Download Windows ISO
2. Configure in WinBoat settings
3. Specify ISO path
4. Run custom installation

### Container Management

**View Containers:**
```bash
docker ps -a | grep winboat
```

**Container Logs:**
```bash
docker logs <container-id>
```

**Backup Container:**
```bash
docker commit <container-id> winboat-backup
```

## Security Considerations

### Isolation

- Windows runs in container (isolated from host)
- Network access controlled by Docker
- File access limited to mounted directories

### Recommendations

- Keep Windows container updated
- Use Windows Defender (included)
- Don't disable container isolation
- Review file sharing permissions

## Getting Help

- **WinBoat GitHub**: https://github.com/TibixDev/winboat
- **Issues**: https://github.com/TibixDev/winboat/issues
- **Bazzite AI Issues**: https://github.com/atrawog/bazzite-ai/issues

## Related Documentation

- [DEVCONTAINER.md](DEVCONTAINER.md) - Linux container development
- [HOST-SETUP-GPU.md](HOST-SETUP-GPU.md) - GPU configuration
- [CLAUDE.md](../CLAUDE.md) - Repository overview
