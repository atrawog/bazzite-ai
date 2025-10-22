export repo_organization := env("GITHUB_REPOSITORY_OWNER", "atrawog")
export image_name := env("IMAGE_NAME", "bazzite-ai")
export default_tag := env("DEFAULT_TAG", "latest")
export bib_image := env("BIB_IMAGE", "quay.io/centos-bootc/bootc-image-builder:latest")
export release_dir := "releases"
export SUDO_DISPLAY := if `if [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; then echo true; fi` == "true" { "true" } else { "false" }
export SUDOIF := if `id -u` == "0" { "" } else if SUDO_DISPLAY == "true" { "sudo --askpass" } else { "sudo" }
export PODMAN := if path_exists("/usr/bin/podman") == "true" { env("PODMAN", "/usr/bin/podman") } else if path_exists("/usr/bin/docker") == "true" { env("PODMAN", "docker") } else { env("PODMAN", "exit 1 ; ") }

alias build-vm := build-qcow2
alias rebuild-vm := rebuild-qcow2
alias run-vm := run-vm-qcow2

[private]
default:
    @just --list

# Check Just Syntax
[group('Just')]
check:
    #!/usr/bin/env bash
    find . -type f -name "*.just" | while read -r file; do
      echo "Checking syntax: $file"
      just --unstable --fmt --check -f $file
    done
    echo "Checking syntax: Justfile"
    just --unstable --fmt --check -f Justfile

# Fix Just Syntax
[group('Just')]
fix:
    #!/usr/bin/env bash
    find . -type f -name "*.just" | while read -r file; do
      echo "Checking syntax: $file"
      just --unstable --fmt -f $file
    done
    echo "Checking syntax: Justfile"
    just --unstable --fmt -f Justfile || { exit 1; }

# Clean Repo
[group('Utility')]
clean:
    #!/usr/bin/env bash
    set -euxo pipefail
    touch _build
    find *_build* -exec rm -rf {} \;
    rm -f previous.manifest.json
    rm -f changelog.md
    rm -f output.env

# Sudo Clean Repo
[group('Utility')]
[private]
sudo-clean:
    ${SUDOIF} just clean

build $target_image=image_name $tag=default_tag:
    #!/usr/bin/env bash

    # Get Version
    ver="${tag}-$(date +%Y%m%d)"

    BUILD_ARGS=()
    BUILD_ARGS+=("--build-arg" "IMAGE_NAME=${image_name}")
    BUILD_ARGS+=("--build-arg" "IMAGE_VENDOR=${repo_organization}")
    if [[ -z "$(git status -s)" ]]; then
      BUILD_ARGS+=("--build-arg" "SHA_HEAD_SHORT=$(git rev-parse --short HEAD)")
    fi

    ${PODMAN} build \
      "${BUILD_ARGS[@]}" \
      --pull=newer \
      --tag "${image_name}:${tag}" \
      .

_rootful_load_image $target_image=image_name $tag=default_tag:
    #!/usr/bin/env bash
    set -euxo pipefail

    if [[ -n "${SUDO_USER:-}" || "${UID}" -eq "0" ]]; then
      echo "Already root or running under sudo, no need to load image from user ${PODMAN}."
      exit 0
    fi

    set +e
    resolved_tag=$(${PODMAN} inspect -t image "${target_image}:${tag}" | jq -r '.[].RepoTags.[0]')
    return_code=$?
    set -e

    if [[ $return_code -eq 0 ]]; then
      # Load into Rootful ${PODMAN}
      ID=$(${SUDOIF} ${PODMAN} images --filter reference="${target_image}:${tag}" --format "'{{ '{{.ID}}' }}'")
      if [[ -z "$ID" ]]; then
        COPYTMP=$(mktemp -p "${PWD}" -d -t _build_podman_scp.XXXXXXXXXX)
        ${SUDOIF} TMPDIR=${COPYTMP} ${PODMAN} image scp ${UID}@localhost::"${target_image}:${tag}" root@localhost::"${target_image}:${tag}"
        rm -rf "${COPYTMP}"
      fi
    else
      # Make sure the image is present and/or up to date
      ${SUDOIF} ${PODMAN} pull "${target_image}:${tag}"
    fi

_build-bib $target_image $tag $type $config: (_rootful_load_image target_image tag)
    #!/usr/bin/env bash
    set -euo pipefail

    mkdir -p "output"

    echo "Cleaning up previous build"
    if [[ $type == iso ]]; then
      sudo rm -rf "output/bootiso" || true
    else
      sudo rm -rf "output/${type}" || true
    fi

    args="--type ${type}"

    if [[ $target_image == localhost/* ]]; then
      args+=" --local"
    fi

    sudo ${PODMAN} run \
      --rm \
      -it \
      --privileged \
      --pull=newer \
      --net=host \
      --security-opt label=type:unconfined_t \
      -v $(pwd)/${config}:/config.toml:ro \
      -v $(pwd)/output:/output \
      -v /var/lib/containers/storage:/var/lib/containers/storage \
      "${bib_image}" \
      --rootfs btrfs \
      ${args} \
      "${target_image}"

    sudo chown -R $USER:$USER output

_rebuild-bib $target_image $tag $type $config: (build target_image tag) && (_build-bib target_image tag type config)

[group('Build Virtual Machine Image')]
build-qcow2 $target_image=("localhost/" + image_name) $tag=default_tag: && (_build-bib target_image tag "qcow2" "image.toml")

[group('Build Virtual Machine Image')]
build-raw $target_image=("localhost/" + image_name) $tag=default_tag: && (_build-bib target_image tag "raw" "image.toml")

[group('Build Virtual Machine Image')]
build-iso $target_image=("localhost/" + image_name) $tag=default_tag: && (_build-bib target_image tag "iso" "iso.toml")

[group('Build Virtual Machine Image')]
rebuild-qcow2 $target_image=("localhost/" + image_name) $tag=default_tag: && (_rebuild-bib target_image tag "qcow2" "image.toml")

[group('Build Virtual Machine Image')]
rebuild-raw $target_image=("localhost/" + image_name) $tag=default_tag: && (_rebuild-bib target_image tag "raw" "image.toml")

[group('Build Virtual Machine Image')]
rebuild-iso $target_image=("localhost/" + image_name) $tag=default_tag: && (_rebuild-bib target_image tag "iso" "iso.toml")

[group('Build Virtual Machine Image')]
build-iso-nvidia $target_image=("localhost/" + image_name + "-nvidia") $tag=default_tag: && (_build-bib target_image tag "iso" "iso-nvidia.toml")

[group('Build Virtual Machine Image')]
rebuild-iso-nvidia $target_image=("localhost/" + image_name + "-nvidia") $tag=default_tag: && (_rebuild-bib target_image tag "iso" "iso-nvidia.toml")

[group('Build Virtual Machine Image')]
build-iso-all $tag=default_tag: (build-iso ("localhost/" + image_name) tag) (build-iso-nvidia ("localhost/" + image_name + "-nvidia") tag)

[group('Build Virtual Machine Image')]
rebuild-iso-all $tag=default_tag: (rebuild-iso ("localhost/" + image_name) tag) (rebuild-iso-nvidia ("localhost/" + image_name + "-nvidia") tag)

_run-vm $target_image $tag $type $config:
    #!/usr/bin/env bash
    set -euxo pipefail

    image_file="output/${type}/disk.${type}"

    if [[ $type == iso ]]; then
      image_file="output/bootiso/install.iso"
    fi

    if [[ ! -f "${image_file}" ]]; then
      just "build-${type}" "$target_image" "$tag"
    fi

    # Determine which port to use
    port=8006;
    while grep -q :${port} <<< $(ss -tunalp); do
      port=$(( port + 1 ))
    done
    echo "Using Port: ${port}"
    echo "Connect to http://localhost:${port}"
    run_args=()
    run_args+=(--rm --privileged)
    run_args+=(--pull=newer)
    run_args+=(--publish "127.0.0.1:${port}:8006")
    run_args+=(--env "CPU_CORES=4")
    run_args+=(--env "RAM_SIZE=8G")
    run_args+=(--env "DISK_SIZE=64G")
    # run_args+=(--env "BOOT_MODE=windows_secure")
    run_args+=(--env "TPM=Y")
    run_args+=(--env "GPU=Y")
    run_args+=(--device=/dev/kvm)
    run_args+=(--volume "${PWD}/${image_file}":"/boot.${type}")
    run_args+=(docker.io/qemux/qemu-docker)
    ${PODMAN} run "${run_args[@]}" &
    xdg-open http://localhost:${port}
    fg "%${PODMAN}"

[group('Run Virtual Machine')]
run-vm-qcow2 $target_image=("localhost/" + image_name) $tag=default_tag: && (_run-vm target_image tag "qcow2" "image-builder.config.toml")

[group('Run Virtual Machine')]
run-vm-raw $target_image=("localhost/" + image_name) $tag=default_tag: && (_run-vm target_image tag "raw" "image-builder.config.toml")

[group('Run Virtual Machine')]
run-vm-iso $target_image=("localhost/" + image_name) $tag=default_tag: && (_run-vm target_image tag "iso" "image-builder-iso.config.toml")

[group('Run Virtual Machine')]
run-vm-iso-nvidia $target_image=("localhost/" + image_name + "-nvidia") $tag=default_tag: && (_run-vm target_image tag "iso" "image-builder-iso.config.toml")

# Build devcontainer image locally
[group('Devcontainer')]
build-devcontainer $tag=default_tag:
    ${PODMAN} build \
      -f Containerfile.devcontainer \
      --build-arg FEDORA_VERSION=42 \
      --tag "bazzite-ai-devcontainer:${tag}" \
      .

# Rebuild devcontainer (no cache)
[group('Devcontainer')]
rebuild-devcontainer $tag=default_tag:
    ${PODMAN} build --no-cache \
      -f Containerfile.devcontainer \
      --build-arg FEDORA_VERSION=42 \
      --tag "bazzite-ai-devcontainer:${tag}" \
      .

# Run devcontainer with GPU
[group('Devcontainer')]
run-devcontainer $tag=default_tag:
    ${PODMAN} run --rm -it \
      --device nvidia.com/gpu=all \
      --security-opt label=disable \
      -v $(pwd):/workspace:Z \
      -w /workspace \
      "bazzite-ai-devcontainer:${tag}" \
      /bin/zsh

# Test CUDA in devcontainer
[group('Devcontainer')]
test-cuda-devcontainer $tag=default_tag:
    ${PODMAN} run --rm \
      --device nvidia.com/gpu=all \
      --security-opt label=disable \
      "bazzite-ai-devcontainer:${tag}" \
      nvidia-smi

# Run devcontainer without GPU
[group('Devcontainer')]
run-devcontainer-no-gpu $tag=default_tag:
    ${PODMAN} run --rm -it \
      -v $(pwd):/workspace:Z \
      -w /workspace \
      "bazzite-ai-devcontainer:${tag}" \
      /bin/zsh

# Pull pre-built devcontainer
[group('Devcontainer')]
pull-devcontainer $tag=default_tag:
    ${PODMAN} pull "ghcr.io/${repo_organization}/bazzite-ai-devcontainer:${tag}"

# Clean devcontainer images
[group('Devcontainer')]
clean-devcontainer:
    ${PODMAN} rmi bazzite-ai-devcontainer || true
    ${PODMAN} rmi ghcr.io/${repo_organization}/bazzite-ai-devcontainer || true

# Private helper: Generate date-based release tag
[private]
_release-tag:
    @echo "42.$(date +%Y%m%d)"

# Private helper: Check if ISOs exist and confirm rebuild
[private]
_release-check-isos tag:
    #!/usr/bin/env bash
    set -euo pipefail
    tag="{{ tag }}"

    iso_base="${image_name}-${tag}.iso"
    iso_nvidia="${image_name}-nvidia-${tag}.iso"

    if [[ -f "$iso_base" || -f "$iso_nvidia" ]]; then
      echo "Found existing ISO(s):"
      [[ -f "$iso_base" ]] && ls -lh "$iso_base"
      [[ -f "$iso_nvidia" ]] && ls -lh "$iso_nvidia"
      echo
      read -p "Rebuild ISOs? [y/N] " -n 1 -r
      echo
      if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Using existing ISOs"
        exit 1
      fi
    fi

# Private helper: Generate release notes
[private]
_release-notes tag:
    #!/usr/bin/env bash
    set -euo pipefail
    tag="{{ tag }}"

    iso_base="${image_name}-${tag}.iso"
    iso_nvidia="${image_name}-nvidia-${tag}.iso"

    # Get container image digests
    base_digest=$(podman inspect localhost/${image_name}:latest 2>/dev/null | jq -r '.[0].Digest' || echo "unknown")
    nvidia_digest=$(podman inspect localhost/${image_name}-nvidia:latest 2>/dev/null | jq -r '.[0].Digest' || echo "unknown")

    cat <<EOF
    # Bazzite AI ${tag}

    ## Container Images

    - \`ghcr.io/${repo_organization}/${image_name}:${tag}\` (Digest: ${base_digest})
    - \`ghcr.io/${repo_organization}/${image_name}-nvidia:${tag}\` (Digest: ${nvidia_digest})

    All images are signed with cosign and can be verified using the public key in this repository.

    ## ISO Downloads

    Download the appropriate ISO for your hardware:

    - **${iso_base}** - For AMD/Intel GPUs (KDE Plasma)
    - **${iso_nvidia}** - For NVIDIA GPUs (KDE Plasma)

    **Important:** Always verify your download using the provided SHA256 checksums:
    \`\`\`bash
    sha256sum -c SHA256SUMS
    \`\`\`

    ## Installation

    ### Fresh Install
    1. Download the appropriate ISO
    2. Create a bootable USB using [Fedora Media Writer](https://fedoraproject.org/workstation/download)
    3. Boot from USB and follow installation prompts

    ### For Existing Bazzite Users

    Rebase to this version:

    **AMD/Intel GPUs:**
    \`\`\`bash
    rpm-ostree rebase ostree-image-signed:docker://ghcr.io/${repo_organization}/${image_name}:${tag}
    \`\`\`

    **NVIDIA GPUs:**
    \`\`\`bash
    rpm-ostree rebase ostree-image-signed:docker://ghcr.io/${repo_organization}/${image_name}-nvidia:${tag}
    \`\`\`

    Then reboot to complete the update.

    ## Documentation

    - [Installation Guide](https://github.com/${repo_organization}/${image_name}#installation)
    - [ISO Build Instructions](https://github.com/${repo_organization}/${image_name}/blob/main/docs/ISO-BUILD.md)

    ---

    Built with Claude Code: https://claude.com/claude-code
    EOF

# Pull container images from GHCR and tag for local use
[group('Release')]
release-pull tag=`just _release-tag`:
    #!/usr/bin/env bash
    set -euo pipefail
    tag="{{ tag }}"

    echo "Pulling container images for tag: ${tag}"
    echo

    # Pull base image
    echo "Pulling ghcr.io/${repo_organization}/${image_name}:${tag}..."
    podman pull "ghcr.io/${repo_organization}/${image_name}:${tag}" || \
      podman pull "ghcr.io/${repo_organization}/${image_name}:latest"

    # Pull NVIDIA image
    echo "Pulling ghcr.io/${repo_organization}/${image_name}-nvidia:${tag}..."
    podman pull "ghcr.io/${repo_organization}/${image_name}-nvidia:${tag}" || \
      podman pull "ghcr.io/${repo_organization}/${image_name}-nvidia:latest"

    # Tag for local use
    echo
    echo "Tagging images for local use..."
    podman tag "ghcr.io/${repo_organization}/${image_name}:latest" "localhost/${image_name}:latest"
    podman tag "ghcr.io/${repo_organization}/${image_name}-nvidia:latest" "localhost/${image_name}-nvidia:latest"

    echo
    echo "✓ Images ready for ISO building"

# Build both ISO variants with confirmation if they exist
[group('Release')]
release-build-isos tag=`just _release-tag`: (_release-check-isos tag)
    #!/usr/bin/env bash
    set -euo pipefail
    tag="{{ tag }}"

    iso_base="${image_name}-${tag}.iso"
    iso_nvidia="${image_name}-nvidia-${tag}.iso"

    echo "Building ISOs for release: ${tag}"
    echo "This will take approximately 60-120 minutes total"
    echo

    # Build base ISO
    echo "Building base ISO..."
    just build-iso "localhost/${image_name}" latest

    if [[ -f "output/bootiso/install.iso" ]]; then
      mv output/bootiso/install.iso "$iso_base"
      echo "✓ Base ISO created: $iso_base ($(du -h "$iso_base" | cut -f1))"
    else
      echo "✗ Base ISO build failed"
      exit 1
    fi

    echo

    # Build NVIDIA ISO
    echo "Building NVIDIA ISO..."
    just build-iso-nvidia "localhost/${image_name}-nvidia" latest

    if [[ -f "output/bootiso/install.iso" ]]; then
      mv output/bootiso/install.iso "$iso_nvidia"
      echo "✓ NVIDIA ISO created: $iso_nvidia ($(du -h "$iso_nvidia" | cut -f1))"
    else
      echo "✗ NVIDIA ISO build failed"
      exit 1
    fi

    echo
    echo "✓ Both ISOs built successfully"

# Generate and verify SHA256 checksums for ISOs
[group('Release')]
release-checksums:
    #!/usr/bin/env bash
    set -euo pipefail

    # Find all ISO files
    isos=(${image_name}-*.iso)

    if [[ ${#isos[@]} -eq 0 || ! -f "${isos[0]}" ]]; then
      echo "✗ No ISO files found"
      echo "Run 'just release-build-isos' first"
      exit 1
    fi

    echo "Generating SHA256 checksums..."
    sha256sum ${image_name}-*.iso > SHA256SUMS

    echo "Verifying checksums..."
    sha256sum -c SHA256SUMS

    echo
    echo "✓ Checksums generated and verified"
    echo
    cat SHA256SUMS

# Organize release files into releases/ directory structure
[group('Release')]
release-organize tag=`just _release-tag`:
    #!/usr/bin/env bash
    set -euo pipefail
    tag="{{ tag }}"

    release_path="${release_dir}/${tag}"

    echo "Organizing release files for ${tag}..."
    echo

    # Create release directory
    mkdir -p "${release_path}"

    # Move ISOs if they exist in root
    moved_files=()
    for pattern in "*.iso" "*.torrent" "*-magnets.txt" "SHA256SUMS"; do
      for file in ${pattern}; do
        if [[ -f "$file" ]]; then
          echo "Moving $file to ${release_path}/"
          mv "$file" "${release_path}/"
          moved_files+=("$file")
        fi
      done
    done

    if [[ ${#moved_files[@]} -eq 0 ]]; then
      echo "ℹ No files to move (already organized or not built yet)"
    else
      echo
      echo "✓ Moved ${#moved_files[@]} file(s) to ${release_path}/"
    fi

    # Update or create 'latest' symlink
    echo
    echo "Updating ${release_dir}/latest symlink..."
    cd "${release_dir}" && ln -sf "${tag}" latest

    echo "✓ Release ${tag} organized"
    echo
    echo "Contents:"
    ls -lh "${release_path}/"

# Create GitHub release with ISOs and checksums
[group('Release')]
release-create tag=`just _release-tag`:
    #!/usr/bin/env bash
    set -euo pipefail
    tag="{{ tag }}"

    release_path="${release_dir}/${tag}"
    iso_base="${image_name}-${tag}.iso"
    iso_nvidia="${image_name}-nvidia-${tag}.iso"

    # Check prerequisites
    if ! command -v gh &> /dev/null; then
      echo "✗ GitHub CLI (gh) not found"
      echo "Install with: sudo dnf install gh"
      exit 1
    fi

    # Check files exist in releases directory
    if [[ ! -f "${release_path}/${iso_base}" ]]; then
      echo "✗ Base ISO not found: ${release_path}/${iso_base}"
      echo "Run 'just release-organize' first"
      exit 1
    fi

    if [[ ! -f "${release_path}/${iso_nvidia}" ]]; then
      echo "✗ NVIDIA ISO not found: ${release_path}/${iso_nvidia}"
      echo "Run 'just release-organize' first"
      exit 1
    fi

    if [[ ! -f "${release_path}/SHA256SUMS" ]]; then
      echo "✗ SHA256SUMS not found in ${release_path}"
      echo "Run 'just release-organize' first"
      exit 1
    fi

    # Check if release exists
    if gh release view "$tag" -R "${repo_organization}/${image_name}" &>/dev/null; then
      echo "Release $tag already exists"
      read -p "Delete and recreate? [y/N] " -n 1 -r
      echo
      if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Deleting existing release..."
        gh release delete "$tag" -R "${repo_organization}/${image_name}" --yes
      else
        echo "Aborted"
        exit 1
      fi
    fi

    echo "Creating GitHub release: ${tag}"
    echo

    # Check if torrents exist
    torrents_exist=false
    if [[ -f "${release_path}/${iso_base}.torrent" ]] && [[ -f "${release_path}/${iso_nvidia}.torrent" ]]; then
      torrents_exist=true
      echo "ℹ Torrent files found, will be included in release"
    else
      echo "ℹ No torrent files found (ISOs too large for GitHub, torrents recommended)"
    fi

    # Prepare release assets (with full paths)
    release_files=("${release_path}/SHA256SUMS")

    # Add torrent files if they exist (small enough for GitHub)
    if $torrents_exist; then
      release_files+=("${release_path}/${iso_base}.torrent" "${release_path}/${iso_nvidia}.torrent")
    fi

    # Generate release notes with torrent info if available
    if $torrents_exist && [[ -f "${release_path}/${tag}-magnets.txt" ]]; then
      # Extract magnet links
      magnet_base=$(grep -A1 "Base ISO" "${release_path}/${tag}-magnets.txt" | tail -n1 || echo "")
      magnet_nvidia=$(grep -A1 "NVIDIA ISO" "${release_path}/${tag}-magnets.txt" | tail -n1 || echo "")

      notes=$(cat <<EOF
    # Bazzite AI ${tag}

    ## Download Options

    ### Option 1: Torrent (Recommended - 8GB+ files)

    The ISO files are distributed via BitTorrent due to GitHub's 2GB file size limit.

    **Base ISO (AMD/Intel GPUs) - 8.2GB:**
    - Download: [bazzite-ai-${tag}.iso.torrent](https://github.com/${repo_organization}/${image_name}/releases/download/${tag}/${iso_base}.torrent)
    - Magnet link: \`${magnet_base}\`

    **NVIDIA ISO - 8.3GB:**
    - Download: [bazzite-ai-nvidia-${tag}.iso.torrent](https://github.com/${repo_organization}/${image_name}/releases/download/${tag}/${iso_nvidia}.torrent)
    - Magnet link: \`${magnet_nvidia}\`

    **How to download via torrent:**
    1. Install a BitTorrent client:
       - Linux: Transmission, qBittorrent, or Deluge
       - Windows/Mac: qBittorrent or Transmission
    2. Click the .torrent file link above OR copy the magnet link
    3. Open in your torrent client
    4. After download completes, verify with SHA256SUMS (see below)

    ### Option 2: Container Image Rebase (Existing Bazzite Users)

    If you already have Bazzite installed, rebase to Bazzite AI:

    **AMD/Intel GPUs:**
    \`\`\`bash
    rpm-ostree rebase ostree-image-signed:docker://ghcr.io/${repo_organization}/${image_name}:${tag}
    \`\`\`

    **NVIDIA GPUs:**
    \`\`\`bash
    rpm-ostree rebase ostree-image-signed:docker://ghcr.io/${repo_organization}/${image_name}-nvidia:${tag}
    \`\`\`

    Then reboot to complete the update.

    ## Verify Your Download

    **SHA256 Checksums:**
    \`\`\`
    $(cat "${release_path}/SHA256SUMS")
    \`\`\`

    After downloading the ISO, verify it:
    \`\`\`bash
    sha256sum -c SHA256SUMS
    \`\`\`

    ## Container Images

    - \`ghcr.io/${repo_organization}/${image_name}:${tag}\`
    - \`ghcr.io/${repo_organization}/${image_name}-nvidia:${tag}\`

    All images are signed with cosign and can be verified using the public key in this repository.

    ## Documentation

    - [Installation Guide](https://github.com/${repo_organization}/${image_name}#installation)
    - [ISO Build Instructions](https://github.com/${repo_organization}/${image_name}/blob/main/docs/ISO-BUILD.md)
    - [Torrent Guide](https://github.com/${repo_organization}/${image_name}/blob/main/docs/TORRENTS.md)

    ---

    Built with Claude Code: https://claude.com/claude-code
    EOF
    )
    else
      # Fallback release notes without torrents
      notes=$(cat <<EOF
    # Bazzite AI ${tag}

    ## Download Option: Container Image Rebase

    **Note:** ISO files are being prepared for torrent distribution (8GB+ files exceed GitHub's 2GB limit).

    For now, rebase from an existing Bazzite installation:

    **AMD/Intel GPUs:**
    \`\`\`bash
    rpm-ostree rebase ostree-image-signed:docker://ghcr.io/${repo_organization}/${image_name}:${tag}
    \`\`\`

    **NVIDIA GPUs:**
    \`\`\`bash
    rpm-ostree rebase ostree-image-signed:docker://ghcr.io/${repo_organization}/${image_name}-nvidia:${tag}
    \`\`\`

    ## Container Images

    - \`ghcr.io/${repo_organization}/${image_name}:${tag}\`
    - \`ghcr.io/${repo_organization}/${image_name}-nvidia:${tag}\`

    All images are signed with cosign.

    ## Documentation

    - [Installation Guide](https://github.com/${repo_organization}/${image_name}#installation)
    - [ISO Build Instructions](https://github.com/${repo_organization}/${image_name}/blob/main/docs/ISO-BUILD.md)

    ---

    Built with Claude Code: https://claude.com/claude-code
    EOF
    )
    fi

    # Create release
    gh release create "$tag" \
      --repo "${repo_organization}/${image_name}" \
      --title "Bazzite AI ${tag}" \
      --notes "$notes" \
      "${release_files[@]}"

    echo
    echo "✓ Release created: https://github.com/${repo_organization}/${image_name}/releases/tag/${tag}"
    if $torrents_exist; then
      echo "✓ Torrent files uploaded"
      echo "ℹ Start seeding with: just release-seed-start ${tag}"
    fi

# Full automated release workflow
[group('Release')]
release tag=`just _release-tag`:
    #!/usr/bin/env bash
    set -euo pipefail
    tag="{{ tag }}"

    echo "==================================="
    echo "Bazzite AI Release Builder"
    echo "==================================="
    echo
    echo "Release tag: ${tag}"
    echo

    read -p "Continue with full release workflow? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "Aborted"
      exit 1
    fi

    echo
    echo "Step 1/7: Pulling container images..."
    just release-pull "$tag"

    echo
    echo "Step 2/7: Building ISOs..."
    just release-build-isos "$tag" || exit 1

    echo
    echo "Step 3/7: Generating checksums..."
    just release-checksums

    echo
    echo "Step 4/7: Organizing files into releases/ directory..."
    just release-organize "$tag"

    echo
    echo "Step 5/7: Creating torrents..."
    just release-create-torrents "$tag"

    echo
    echo "Step 6/7: Starting seeding service..."
    if systemctl --user is-enabled bazzite-ai-seeding.service &>/dev/null; then
      just release-seed-start "$tag"
    else
      echo "ℹ Seeding service not set up"
      echo "Run 'just release-setup-seeding' to enable automatic seeding"
      echo "For now, you can seed manually with: just release-seed-start ${tag}"
    fi

    echo
    echo "Step 7/7: Creating GitHub release..."
    just release-create "$tag"

    echo
    echo "==================================="
    echo "✓ Release complete!"
    echo "==================================="
    echo
    if systemctl --user is-active bazzite-ai-seeding.service &>/dev/null; then
      echo "✓ Seeding in progress"
      echo "  Check status: just release-seed-status"
      echo "  Stop seeding: just release-seed-stop"
    fi

# Upload files to an existing GitHub release
[group('Release')]
release-upload tag files:
    #!/usr/bin/env bash
    set -euo pipefail
    tag="{{ tag }}"
    files="{{ files }}"

    if ! command -v gh &> /dev/null; then
      echo "✗ GitHub CLI (gh) not found"
      exit 1
    fi

    if ! gh release view "$tag" -R "${repo_organization}/${image_name}" &>/dev/null; then
      echo "✗ Release $tag does not exist"
      echo "Run 'just release-create $tag' first"
      exit 1
    fi

    echo "Uploading to release: ${tag}"
    gh release upload "$tag" {{ files }} -R "${repo_organization}/${image_name}"
    echo "✓ Files uploaded"

# List all GitHub releases
[group('Release')]
release-list:
    #!/usr/bin/env bash
    if ! command -v gh &> /dev/null; then
      echo "✗ GitHub CLI (gh) not found"
      exit 1
    fi

    gh release list -R "${repo_organization}/${image_name}"

# Remove built ISO artifacts from working directory
[group('Release')]
release-clean:
    #!/usr/bin/env bash
    set -euo pipefail

    files_to_remove=()

    # Find ISOs in root (old location)
    for iso in ${image_name}-*.iso; do
      [[ -f "$iso" ]] && files_to_remove+=("$iso")
    done

    # Find torrents in root (old location)
    for torrent in ${image_name}-*.torrent; do
      [[ -f "$torrent" ]] && files_to_remove+=("$torrent")
    done

    # Find magnet links in root (old location)
    for magnets in *-magnets.txt; do
      [[ -f "$magnets" ]] && files_to_remove+=("$magnets")
    done

    # Find checksums in root (old location)
    [[ -f "SHA256SUMS" ]] && files_to_remove+=("SHA256SUMS")

    # Also offer to remove releases/ directory
    has_releases_dir=false
    if [[ -d "${release_dir}" ]]; then
      has_releases_dir=true
    fi

    if [[ ${#files_to_remove[@]} -eq 0 ]] && [[ "$has_releases_dir" == "false" ]]; then
      echo "No release artifacts to clean"
      exit 0
    fi

    if [[ ${#files_to_remove[@]} -gt 0 ]]; then
      echo "Files to remove from root:"
      for file in "${files_to_remove[@]}"; do
        ls -lh "$file"
      done
      echo
    fi

    if [[ "$has_releases_dir" == "true" ]]; then
      echo "Directory to remove:"
      du -sh "${release_dir}"
      echo
    fi

    echo
    read -p "Delete these artifacts? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      if [[ ${#files_to_remove[@]} -gt 0 ]]; then
        rm -f "${files_to_remove[@]}"
        echo "✓ Removed ${#files_to_remove[@]} file(s) from root"
      fi
      if [[ "$has_releases_dir" == "true" ]]; then
        rm -rf "${release_dir}"
        echo "✓ Removed ${release_dir}/ directory"
      fi
      echo "✓ Cleanup complete"
    else
      echo "Aborted"
    fi

# Verify checksums and signatures of release artifacts
[group('Release')]
release-verify:
    #!/usr/bin/env bash
    set -euo pipefail

    if [[ ! -f "SHA256SUMS" ]]; then
      echo "✗ SHA256SUMS not found"
      exit 1
    fi

    echo "Verifying SHA256 checksums..."
    if sha256sum -c SHA256SUMS; then
      echo "✓ All checksums verified"
    else
      echo "✗ Checksum verification failed"
      exit 1
    fi

    echo

    # Check for cosign
    if command -v cosign &> /dev/null && [[ -f "cosign.pub" ]]; then
      echo "Verifying container image signatures..."

      for variant in "" "-nvidia"; do
        image="ghcr.io/${repo_organization}/${image_name}${variant}:latest"
        echo "Verifying: $image"
        if cosign verify --key cosign.pub "$image" &>/dev/null; then
          echo "✓ Signature valid"
        else
          echo "✗ Signature verification failed"
        fi
      done
    else
      echo "ℹ Skipping signature verification (cosign not available)"
    fi

# Create torrent files for ISOs with public trackers
[group('Release')]
release-create-torrents tag=`just _release-tag`:
    #!/usr/bin/env bash
    set -euo pipefail
    tag="{{ tag }}"

    release_path="${release_dir}/${tag}"
    iso_base="${release_path}/${image_name}-${tag}.iso"
    iso_nvidia="${release_path}/${image_name}-nvidia-${tag}.iso"

    # Check prerequisites
    if ! command -v mktorrent &> /dev/null && ! command -v transmission-create &> /dev/null; then
      echo "✗ No torrent creation tool found"
      echo "Install with: sudo dnf install mktorrent"
      echo "Or: sudo dnf install transmission-cli"
      exit 1
    fi

    # Check if ISOs exist
    if [[ ! -f "$iso_base" ]]; then
      echo "✗ Base ISO not found: $iso_base"
      echo "Run 'just release-organize' first"
      exit 1
    fi

    if [[ ! -f "$iso_nvidia" ]]; then
      echo "✗ NVIDIA ISO not found: $iso_nvidia"
      echo "Run 'just release-organize' first"
      exit 1
    fi

    echo "Creating torrent files..."
    echo

    # Public trackers for open source projects
    TRACKERS=(
      "udp://tracker.opentrackr.org:1337/announce"
      "udp://open.stealth.si:80/announce"
      "udp://tracker.torrent.eu.org:451/announce"
      "udp://tracker.openbittorrent.com:6969/announce"
      "udp://tracker.tiny-vps.com:6969/announce"
      "udp://exodus.desync.com:6969/announce"
    )

    # Build tracker args
    TRACKER_ARGS=()
    for tracker in "${TRACKERS[@]}"; do
      if command -v mktorrent &> /dev/null; then
        TRACKER_ARGS+=("-a" "$tracker")
      else
        TRACKER_ARGS+=("-t" "$tracker")
      fi
    done

    # Create base ISO torrent
    echo "Creating torrent for $(basename ${iso_base})..."
    if command -v mktorrent &> /dev/null; then
      mktorrent "${TRACKER_ARGS[@]}" \
        -c "Bazzite AI ${tag} - AMD/Intel GPU variant. Immutable Linux gaming OS with AI/ML tools." \
        -n "$(basename ${iso_base})" \
        -o "${iso_base}.torrent" \
        "$iso_base"
    else
      transmission-create "${TRACKER_ARGS[@]}" \
        -c "Bazzite AI ${tag} - AMD/Intel GPU variant" \
        -o "${iso_base}.torrent" \
        "$iso_base"
    fi
    echo "✓ Created $(basename ${iso_base}).torrent"
    echo

    # Create NVIDIA ISO torrent
    echo "Creating torrent for $(basename ${iso_nvidia})..."
    if command -v mktorrent &> /dev/null; then
      mktorrent "${TRACKER_ARGS[@]}" \
        -c "Bazzite AI ${tag} - NVIDIA GPU variant. Immutable Linux gaming OS with AI/ML tools." \
        -n "$(basename ${iso_nvidia})" \
        -o "${iso_nvidia}.torrent" \
        "$iso_nvidia"
    else
      transmission-create "${TRACKER_ARGS[@]}" \
        -c "Bazzite AI ${tag} - NVIDIA GPU variant" \
        -o "${iso_nvidia}.torrent" \
        "$iso_nvidia"
    fi
    echo "✓ Created $(basename ${iso_nvidia}).torrent"
    echo

    # Generate magnet links
    if command -v transmission-show &> /dev/null; then
      echo "Generating magnet links..."
      {
        echo "# Bazzite AI ${tag} Magnet Links"
        echo
        echo "## Base ISO (AMD/Intel GPUs)"
        transmission-show -m "${iso_base}.torrent"
        echo
        echo "## NVIDIA ISO"
        transmission-show -m "${iso_nvidia}.torrent"
      } > "${release_path}/${tag}-magnets.txt"
      echo "✓ Magnet links saved to ${tag}-magnets.txt"
    else
      echo "ℹ Install transmission-cli to generate magnet links"
    fi

    echo
    echo "✓ Torrent creation complete"
    ls -lh "${release_path}"/*.torrent

# Display torrent information and magnet links
[group('Release')]
release-torrents-info tag=`just _release-tag`:
    #!/usr/bin/env bash
    set -euo pipefail
    tag="{{ tag }}"

    iso_base="${image_name}-${tag}.iso"
    iso_nvidia="${image_name}-nvidia-${tag}.iso"

    if [[ ! -f "${iso_base}.torrent" ]] || [[ ! -f "${iso_nvidia}.torrent" ]]; then
      echo "✗ Torrent files not found"
      echo "Run 'just release-create-torrents' first"
      exit 1
    fi

    if ! command -v transmission-show &> /dev/null; then
      echo "✗ transmission-show not found"
      echo "Install with: sudo dnf install transmission-cli"
      exit 1
    fi

    echo "=========================================="
    echo "Bazzite AI ${tag} Torrent Information"
    echo "=========================================="
    echo

    echo "Base ISO (AMD/Intel GPUs):"
    echo "  File: ${iso_base}"
    echo "  Torrent: ${iso_base}.torrent"
    transmission-show "${iso_base}.torrent" | grep -E "(Name:|Hash:|Total Size:|Piece Size:)"
    echo

    echo "NVIDIA ISO:"
    echo "  File: ${iso_nvidia}"
    echo "  Torrent: ${iso_nvidia}.torrent"
    transmission-show "${iso_nvidia}.torrent" | grep -E "(Name:|Hash:|Total Size:|Piece Size:)"
    echo

    if [[ -f "${tag}-magnets.txt" ]]; then
      echo "Magnet links saved in: ${tag}-magnets.txt"
      echo
      cat "${tag}-magnets.txt"
    fi

# Extract and display magnet links
[group('Release')]
release-magnets tag=`just _release-tag`:
    #!/usr/bin/env bash
    set -euo pipefail
    tag="{{ tag }}"

    if [[ -f "${tag}-magnets.txt" ]]; then
      cat "${tag}-magnets.txt"
    else
      echo "✗ Magnet links file not found: ${tag}-magnets.txt"
      echo "Run 'just release-create-torrents' first"
      exit 1
    fi

# Verify torrent files are valid
[group('Release')]
release-verify-torrents tag=`just _release-tag`:
    #!/usr/bin/env bash
    set -euo pipefail
    tag="{{ tag }}"

    iso_base="${image_name}-${tag}.iso"
    iso_nvidia="${image_name}-nvidia-${tag}.iso"

    echo "Verifying torrent files..."
    echo

    errors=0

    # Check base torrent
    if [[ ! -f "${iso_base}.torrent" ]]; then
      echo "✗ Base torrent not found: ${iso_base}.torrent"
      ((errors++))
    elif ! command -v transmission-show &> /dev/null; then
      echo "ℹ Cannot verify (transmission-show not installed)"
    else
      if transmission-show "${iso_base}.torrent" &>/dev/null; then
        echo "✓ Base torrent valid"
      else
        echo "✗ Base torrent invalid or corrupted"
        ((errors++))
      fi
    fi

    # Check NVIDIA torrent
    if [[ ! -f "${iso_nvidia}.torrent" ]]; then
      echo "✗ NVIDIA torrent not found: ${iso_nvidia}.torrent"
      ((errors++))
    elif command -v transmission-show &> /dev/null; then
      if transmission-show "${iso_nvidia}.torrent" &>/dev/null; then
        echo "✓ NVIDIA torrent valid"
      else
        echo "✗ NVIDIA torrent invalid or corrupted"
        ((errors++))
      fi
    fi

    # Check if ISOs exist
    if [[ ! -f "$iso_base" ]]; then
      echo "✗ Base ISO not found: $iso_base"
      ((errors++))
    else
      echo "✓ Base ISO exists"
    fi

    if [[ ! -f "$iso_nvidia" ]]; then
      echo "✗ NVIDIA ISO not found: $iso_nvidia"
      ((errors++))
    else
      echo "✓ NVIDIA ISO exists"
    fi

    echo

    if [[ $errors -gt 0 ]]; then
      echo "✗ Verification failed with $errors error(s)"
      exit 1
    else
      echo "✓ All torrent files verified"
    fi

# One-time setup of systemd seeding service
[group('Release')]
release-setup-seeding:
    #!/usr/bin/env bash
    ./scripts/setup-seeding-service.sh

# Start seeding torrents for a release
[group('Release')]
release-seed-start tag=`just _release-tag`:
    #!/usr/bin/env bash
    set -euo pipefail
    tag="{{ tag }}"

    release_path="${release_dir}/${tag}"
    iso_base="${image_name}-${tag}.iso"
    iso_nvidia="${image_name}-nvidia-${tag}.iso"
    torrent_base="${release_path}/${iso_base}.torrent"
    torrent_nvidia="${release_path}/${iso_nvidia}.torrent"

    # Check if torrents exist
    if [[ ! -f "${torrent_base}" ]] || [[ ! -f "${torrent_nvidia}" ]]; then
      echo "✗ Torrent files not found in ${release_path}"
      echo "Run 'just release-create-torrents' first"
      exit 1
    fi

    # Check if service is set up
    if ! systemctl --user is-enabled bazzite-ai-seeding.service &>/dev/null; then
      echo "✗ Seeding service not set up"
      echo "Run 'just release-setup-seeding' first"
      exit 1
    fi

    # Check if transmission-remote is available
    if ! command -v transmission-remote &> /dev/null; then
      echo "✗ transmission-remote not found"
      echo "Install with: sudo dnf install transmission-cli"
      exit 1
    fi

    # Start service if not running
    if ! systemctl --user is-active bazzite-ai-seeding.service &>/dev/null; then
      echo "Starting seeding service..."
      systemctl --user start bazzite-ai-seeding.service
      sleep 2
    fi

    echo "Adding torrents to seeder..."
    echo

    # Add base torrent
    if transmission-remote -a "${torrent_base}" 2>/dev/null; then
      echo "✓ Added ${iso_base}.torrent"
    else
      echo "ℹ ${iso_base}.torrent may already be added"
    fi

    # Add NVIDIA torrent
    if transmission-remote -a "${torrent_nvidia}" 2>/dev/null; then
      echo "✓ Added ${iso_nvidia}.torrent"
    else
      echo "ℹ ${iso_nvidia}.torrent may already be added"
    fi

    echo
    echo "✓ Seeding started"
    echo
    just release-seed-status

# Stop seeding service
[group('Release')]
release-seed-stop:
    #!/usr/bin/env bash
    set -euo pipefail

    if systemctl --user is-active bazzite-ai-seeding.service &>/dev/null; then
      echo "Stopping seeding service..."
      systemctl --user stop bazzite-ai-seeding.service
      echo "✓ Service stopped"
    else
      echo "ℹ Service is not running"
    fi

# Show seeding status
[group('Release')]
release-seed-status:
    #!/usr/bin/env bash
    set -euo pipefail

    # Check if service exists
    if ! systemctl --user is-enabled bazzite-ai-seeding.service &>/dev/null; then
      echo "✗ Seeding service not set up"
      echo "Run 'just release-setup-seeding' first"
      exit 1
    fi

    # Check if transmission-remote is available
    if ! command -v transmission-remote &> /dev/null; then
      echo "✗ transmission-remote not found"
      echo "Install with: sudo dnf install transmission-cli"
      exit 1
    fi

    echo "=========================================="
    echo "Bazzite AI Seeding Status"
    echo "=========================================="
    echo

    # Service status
    if systemctl --user is-active bazzite-ai-seeding.service &>/dev/null; then
      echo "Service: ✓ Running"
    else
      echo "Service: ✗ Stopped"
      echo
      echo "Start with: just release-seed-start <tag>"
      exit 0
    fi

    echo
    echo "Torrents:"
    echo

    # Get torrent list
    if transmission-remote -l 2>/dev/null; then
      echo
      echo "Commands:"
      echo "  Stop seeding: just release-seed-stop"
      echo "  View logs:    journalctl --user -u bazzite-ai-seeding -f"
    else
      echo "✗ Cannot connect to transmission-daemon"
      echo "Check service: systemctl --user status bazzite-ai-seeding"
    fi

# Add a specific torrent file to the seeder
[group('Release')]
release-seed-add torrent_file:
    #!/usr/bin/env bash
    set -euo pipefail
    torrent_file="{{ torrent_file }}"

    if [[ ! -f "$torrent_file" ]]; then
      echo "✗ Torrent file not found: $torrent_file"
      exit 1
    fi

    if ! systemctl --user is-active bazzite-ai-seeding.service &>/dev/null; then
      echo "✗ Seeding service not running"
      echo "Start with: systemctl --user start bazzite-ai-seeding"
      exit 1
    fi

    echo "Adding $torrent_file..."
    if transmission-remote -a "$torrent_file"; then
      echo "✓ Torrent added"
    else
      echo "✗ Failed to add torrent"
      exit 1
    fi
