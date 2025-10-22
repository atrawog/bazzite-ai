# Bazzite AI

[![Build Bazzite AI](https://github.com/atrawog/bazzite-ai/actions/workflows/build.yml/badge.svg)](https://github.com/atrawog/bazzite-ai/actions/workflows/build.yml)

This is a custom fork of [Bazzite DX](https://github.com/ublue-os/bazzite-dx) with AI/ML-focused tooling and customizations, building on top of Bazzite with extra developer-specific tools matching [Bluefin DX](https://docs.projectbluefin.io/bluefin-dx/) and [Aurora DX](https://docs.getaurora.dev/dx/aurora-dx-intro) in functionality.

## Installation

Bazzite AI is available in two variants, both with KDE Plasma desktop:
- **bazzite-ai** - For AMD/Intel GPUs
- **bazzite-ai-nvidia** - For NVIDIA GPUs

### Fresh Installation (ISO)

Download the latest ISO from [Releases](https://github.com/atrawog/bazzite-ai/releases/latest):

- **bazzite-ai-*.iso** - For AMD/Intel GPUs
- **bazzite-ai-nvidia-*.iso** - For NVIDIA GPUs

Create a bootable USB drive using your preferred tool:
- [Fedora Media Writer](https://fedoraproject.org/workstation/download) (Recommended)
- [balenaEtcher](https://etcher.balena.io/)
- [Ventoy](https://www.ventoy.net/)

Boot from the USB drive and follow the installation prompts.

### Rebase from Existing Bazzite

To rebase an existing Bazzite installation to Bazzite AI:

**For AMD/Intel GPUs (KDE Plasma):**
```bash
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/atrawog/bazzite-ai:stable
```

**For NVIDIA GPUs (KDE Plasma):**
```bash
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/atrawog/bazzite-ai-nvidia:stable
```

After running the rebase command, reboot your system to complete the installation.

**Note:** To skip signature verification (not recommended), replace `ostree-image-signed:docker://ghcr.io` with `ostree-unverified-registry:ghcr.io`. 

## Acknowledgments

This project is built upon the work from [amyos](https://github.com/astrovm/amyos)

## Metrics

![Alt](https://repobeats.axiom.co/api/embed/8568b042f7cfba9dd477885ed5ee6573ab78bb5e.svg "Repobeats analytics image")
