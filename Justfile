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

# =============================================================================
# Container Commands (base and nvidia variants)
# =============================================================================

# Build base container image locally
[group('Container')]
build-container $tag=default_tag:
    ${PODMAN} build \
      -f Containerfile.container \
      --build-arg FEDORA_VERSION=42 \
      --tag "bazzite-ai-container:${tag}" \
      .

# Build NVIDIA container image locally (requires base)
[group('Container')]
build-container-nvidia $tag=default_tag: (build-container tag)
    ${PODMAN} build \
      -f Containerfile.container-nvidia \
      --build-arg BASE_TAG={{ tag }} \
      --build-arg BASE_IMAGE=localhost/bazzite-ai-container \
      --tag "bazzite-ai-container-nvidia:${tag}" \
      .

# Rebuild both container images (no cache)
[group('Container')]
rebuild-container $tag=default_tag:
    ${PODMAN} build --no-cache \
      -f Containerfile.container \
      --build-arg FEDORA_VERSION=42 \
      --tag "bazzite-ai-container:${tag}" \
      .
    ${PODMAN} build --no-cache \
      -f Containerfile.container-nvidia \
      --build-arg BASE_TAG={{ tag }} \
      --build-arg BASE_IMAGE=localhost/bazzite-ai-container \
      --tag "bazzite-ai-container-nvidia:${tag}" \
      .

# Run base container (CPU-only)
[group('Container')]
run-container $tag=default_tag:
    ${PODMAN} run --rm -it \
      -v $(pwd):/workspace:Z \
      -w /workspace \
      "bazzite-ai-container:${tag}" \
      /bin/zsh

# Run NVIDIA container with GPU
[group('Container')]
run-container-nvidia $tag=default_tag:
    ${PODMAN} run --rm -it \
      --device nvidia.com/gpu=all \
      --security-opt label=disable \
      -v $(pwd):/workspace:Z \
      -w /workspace \
      "bazzite-ai-container-nvidia:${tag}" \
      /bin/zsh

# Test CUDA in NVIDIA container
[group('Container')]
test-cuda-container $tag=default_tag:
    ${PODMAN} run --rm \
      --device nvidia.com/gpu=all \
      --security-opt label=disable \
      "bazzite-ai-container-nvidia:${tag}" \
      nvidia-smi

# Pull pre-built base container
[group('Container')]
pull-container $tag=default_tag:
    ${PODMAN} pull "ghcr.io/${repo_organization}/bazzite-ai-container:${tag}"

# Pull pre-built NVIDIA container
[group('Container')]
pull-container-nvidia $tag=default_tag:
    ${PODMAN} pull "ghcr.io/${repo_organization}/bazzite-ai-container-nvidia:${tag}"

# Clean container images
[group('Container')]
clean-container:
    ${PODMAN} rmi bazzite-ai-container || true
    ${PODMAN} rmi bazzite-ai-container-nvidia || true
    ${PODMAN} rmi ghcr.io/${repo_organization}/bazzite-ai-container || true
    ${PODMAN} rmi ghcr.io/${repo_organization}/bazzite-ai-container-nvidia || true

# Private helper: Generate date-based release tag
[private]
_release-tag:
    @echo "42.$(date +%Y%m%d)"

# Private helper: Check if ISO exists and confirm rebuild
[private]
_release-check-isos tag:
    #!/usr/bin/env bash
    set -euo pipefail
    tag="{{ tag }}"

    iso_file="${image_name}-${tag}.iso"

    if [[ -f "$iso_file" ]]; then
      echo "Found existing ISO:"
      ls -lh "$iso_file"
      echo
      read -p "Rebuild ISO? [y/N] " -n 1 -r
      echo
      if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Using existing ISO"
        exit 1
      fi
    fi

# Private helper: Generate release notes
[private]
_release-notes tag:
    #!/usr/bin/env bash
    set -euo pipefail
    tag="{{ tag }}"

    iso_file="${image_name}-${tag}.iso"

    # Get container image digest
    image_digest=$(podman inspect localhost/${image_name}:latest 2>/dev/null | jq -r '.[0].Digest' || echo "unknown")

    cat <<EOF
    # Bazzite AI ${tag}

    ## Container Image

    - \`ghcr.io/${repo_organization}/${image_name}:${tag}\` (Digest: ${image_digest})

    Unified image with NVIDIA open driver support (works on all hardware: AMD, Intel, NVIDIA).

    All images are signed with cosign and can be verified using the public key in this repository.

    ## ISO Download

    Download the unified ISO (works on all hardware):

    - **${iso_file}** - KDE Plasma (AMD/Intel/NVIDIA GPUs)

    **Important:** Always verify your download using the provided SHA256 checksums:
    \`\`\`bash
    sha256sum -c SHA256SUMS
    \`\`\`

    ## Installation

    ### Fresh Install
    1. Download the ISO
    2. Create a bootable USB using [Fedora Media Writer](https://fedoraproject.org/workstation/download)
    3. Boot from USB and follow installation prompts

    ### For Existing Bazzite Users

    Rebase to this version:

    \`\`\`bash
    rpm-ostree rebase ostree-image-signed:docker://ghcr.io/${repo_organization}/${image_name}:${tag}
    \`\`\`

    Then reboot to complete the update.

    ## Documentation

    - [Installation Guide](https://github.com/${repo_organization}/${image_name}#installation)
    - [ISO Build Instructions](https://github.com/${repo_organization}/${image_name}/blob/main/docs/ISO-BUILD.md)

    ---

    Built with Claude Code: https://claude.com/claude-code
    EOF

# Pull container image from GHCR and tag for local use
[group('Release')]
release-pull tag=`just _release-tag`:
    #!/usr/bin/env bash
    set -euo pipefail
    tag="{{ tag }}"

    echo "Pulling container image for tag: ${tag}"
    echo

    # Pull unified image
    echo "Pulling ghcr.io/${repo_organization}/${image_name}:${tag}..."
    podman pull "ghcr.io/${repo_organization}/${image_name}:${tag}" || \
      podman pull "ghcr.io/${repo_organization}/${image_name}:latest"

    # Tag for local use
    echo
    echo "Tagging image for local use..."
    podman tag "ghcr.io/${repo_organization}/${image_name}:latest" "localhost/${image_name}:latest"

    echo
    echo "✓ Image ready for ISO building"

# Build unified ISO with confirmation if it exists
[group('Release')]
release-build-isos tag=`just _release-tag`: (_release-check-isos tag)
    #!/usr/bin/env bash
    set -euo pipefail
    tag="{{ tag }}"

    iso_file="${image_name}-${tag}.iso"

    echo "Building ISO for release: ${tag}"
    echo "This will take approximately 30-60 minutes"
    echo

    # Build unified ISO
    echo "Building ISO..."
    just build-iso "localhost/${image_name}" latest

    if [[ -f "output/bootiso/install.iso" ]]; then
      mv output/bootiso/install.iso "$iso_file"
      echo "✓ ISO created: $iso_file ($(du -h "$iso_file" | cut -f1))"
    else
      echo "✗ ISO build failed"
      exit 1
    fi

    echo
    echo "✓ ISO built successfully"

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
      for file in $pattern; do
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
    (cd "${release_dir}" && ln -sf "${tag}" latest)

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

    # Get file sizes
    iso_base_size="unknown"
    iso_nvidia_size="unknown"
    if [[ -f "${release_path}/${iso_base}" ]]; then
      iso_base_size=$(du -h "${release_path}/${iso_base}" | cut -f1)
    fi
    if [[ -f "${release_path}/${iso_nvidia}" ]]; then
      iso_nvidia_size=$(du -h "${release_path}/${iso_nvidia}" | cut -f1)
    fi

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
      # Extract magnet links - more robust extraction
      magnet_base=$(grep "^magnet:" "${release_path}/${tag}-magnets.txt" | head -n1 || echo "")
      magnet_nvidia=$(grep "^magnet:" "${release_path}/${tag}-magnets.txt" | tail -n1 || echo "")

      notes=$(cat <<EOF
    # Bazzite AI ${tag}

    ⚠️ **Important:** ISO files (${iso_base_size} & ${iso_nvidia_size}) exceed GitHub's 2GB limit and are **ONLY available via BitTorrent**.

    ## Download ISOs via BitTorrent

    ### Base ISO (AMD/Intel GPUs) - ${iso_base_size}

    **Download options:**
    1. **Torrent file:** [${iso_base}.torrent](https://github.com/${repo_organization}/${image_name}/releases/download/${tag}/${iso_base}.torrent)
    2. **Magnet link:**
       \`\`\`
       ${magnet_base}
       \`\`\`

    ### NVIDIA ISO (NVIDIA GPUs) - ${iso_nvidia_size}

    **Download options:**
    1. **Torrent file:** [${iso_nvidia}.torrent](https://github.com/${repo_organization}/${image_name}/releases/download/${tag}/${iso_nvidia}.torrent)
    2. **Magnet link:**
       \`\`\`
       ${magnet_nvidia}
       \`\`\`

    ### How to Use BitTorrent

    1. **Install a BitTorrent client:**
       - Linux: Transmission (pre-installed on most), qBittorrent, or Deluge
       - Windows/Mac: qBittorrent or Transmission
    2. **Download via torrent file OR magnet link:**
       - Click the .torrent file link above and open it in your client, OR
       - Copy the magnet link and paste it into your client
    3. **Wait for download to complete**
    4. **Verify your download** with SHA256SUMS (see below)
    5. **Please seed after downloading!** Help others by continuing to share the file

    ## Alternative: Rebase from Existing Bazzite

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

    ## Download ISOs

    ⚠️ **ISO files (${iso_base_size} & ${iso_nvidia_size}) are being prepared** for BitTorrent distribution.

    ISO files exceed GitHub's 2GB file size limit and cannot be uploaded directly.
    Torrent files will be added shortly.

    ## Alternative: Rebase from Existing Bazzite

    For immediate installation, rebase from an existing Bazzite system:

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

    # Check prerequisites first
    echo "Checking prerequisites..."
    if ! just release-check-prereqs; then
      echo
      echo "✗ Prerequisites check failed"
      echo "Fix the issues above or run: just release-install-tools"
      exit 1
    fi
    echo

    read -p "Continue with full release workflow? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "Aborted"
      exit 1
    fi

    echo
    echo "Step 1/8: Pulling container images..."
    just release-pull "$tag"

    echo
    echo "Step 2/8: Building ISOs (60-120 minutes)..."
    just release-build-isos "$tag" || exit 1

    echo
    echo "Step 3/8: Generating checksums..."
    just release-checksums

    echo
    echo "Step 4/8: Organizing files into releases/ directory..."
    just release-organize "$tag"

    echo
    echo "Step 5/8: Creating torrents..."
    just release-create-torrents "$tag"

    echo
    echo "Step 6/8: Verifying torrents..."
    just release-verify-torrents "$tag"

    echo
    echo "Step 7/8: Starting seeding service..."
    if systemctl --user is-enabled bazzite-ai-seeding.service &>/dev/null; then
      just release-seed-start "$tag"
    else
      echo "ℹ Seeding service not set up"
      echo "Run 'just release-setup-seeding' to enable automatic seeding"
      echo "For now, you can seed manually with: just release-seed-start ${tag}"
    fi

    echo
    echo "Step 8/8: Creating GitHub release..."
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

# Show comprehensive status of release workflow
[group('Release')]
release-status tag=`just _release-tag`:
    #!/usr/bin/env bash
    set -euo pipefail
    tag="{{ tag }}"

    release_path="${release_dir}/${tag}"
    iso_base="${image_name}-${tag}.iso"
    iso_nvidia="${image_name}-nvidia-${tag}.iso"

    echo "=========================================="
    echo "Bazzite AI Release Status"
    echo "=========================================="
    echo
    echo "Release Tag: ${tag}"
    echo "Release Path: ${release_path}"
    echo

    # Container Images
    echo "Container Images:"
    if podman inspect "ghcr.io/${repo_organization}/${image_name}:${tag}" &>/dev/null 2>&1; then
      echo "  ✓ ghcr.io/${repo_organization}/${image_name}:${tag}"
    elif podman inspect "ghcr.io/${repo_organization}/${image_name}:latest" &>/dev/null 2>&1; then
      echo "  ✓ ghcr.io/${repo_organization}/${image_name}:latest (will use this)"
    else
      echo "  ✗ Base image not found locally"
    fi

    if podman inspect "ghcr.io/${repo_organization}/${image_name}-nvidia:${tag}" &>/dev/null 2>&1; then
      echo "  ✓ ghcr.io/${repo_organization}/${image_name}-nvidia:${tag}"
    elif podman inspect "ghcr.io/${repo_organization}/${image_name}-nvidia:latest" &>/dev/null 2>&1; then
      echo "  ✓ ghcr.io/${repo_organization}/${image_name}-nvidia:latest (will use this)"
    else
      echo "  ✗ NVIDIA image not found locally"
    fi
    echo

    # ISOs
    echo "ISO Files:"
    if [[ -f "${release_path}/${iso_base}" ]]; then
      iso_base_size=$(du -h "${release_path}/${iso_base}" | cut -f1)
      echo "  ✓ ${iso_base} (${iso_base_size})"
    else
      echo "  ✗ ${iso_base} not found"
    fi

    if [[ -f "${release_path}/${iso_nvidia}" ]]; then
      iso_nvidia_size=$(du -h "${release_path}/${iso_nvidia}" | cut -f1)
      echo "  ✓ ${iso_nvidia} (${iso_nvidia_size})"
    else
      echo "  ✗ ${iso_nvidia} not found"
    fi
    echo

    # Checksums
    echo "Checksums:"
    if [[ -f "${release_path}/SHA256SUMS" ]]; then
      echo "  ✓ SHA256SUMS exists"
    else
      echo "  ✗ SHA256SUMS not found"
    fi
    echo

    # Torrents
    echo "Torrent Files:"
    if [[ -f "${release_path}/${iso_base}.torrent" ]]; then
      echo "  ✓ ${iso_base}.torrent"
    else
      echo "  ✗ ${iso_base}.torrent not found"
    fi

    if [[ -f "${release_path}/${iso_nvidia}.torrent" ]]; then
      echo "  ✓ ${iso_nvidia}.torrent"
    else
      echo "  ✗ ${iso_nvidia}.torrent not found"
    fi

    if [[ -f "${release_path}/${tag}-magnets.txt" ]]; then
      echo "  ✓ ${tag}-magnets.txt"
    else
      echo "  ✗ ${tag}-magnets.txt not found"
    fi
    echo

    # Seeding
    echo "Seeding Status:"
    if systemctl --user is-enabled bazzite-ai-seeding.service &>/dev/null; then
      if systemctl --user is-active bazzite-ai-seeding.service &>/dev/null; then
        echo "  ✓ Seeding service running"
        if command -v transmission-remote &> /dev/null; then
          torrent_count=$(transmission-remote -l 2>/dev/null | grep -c "%.%" || echo "0")
          echo "  ✓ Active torrents: ${torrent_count}"
        fi
      else
        echo "  ℹ Seeding service enabled but not running"
      fi
    else
      echo "  ✗ Seeding service not set up"
      echo "    Run: just release-setup-seeding"
    fi
    echo

    # GitHub Release
    echo "GitHub Release:"
    if command -v gh &> /dev/null; then
      if gh release view "${tag}" -R "${repo_organization}/${image_name}" &>/dev/null; then
        echo "  ✓ Release ${tag} exists"
      else
        echo "  ✗ Release ${tag} not found"
      fi
    else
      echo "  ℹ GitHub CLI not available"
    fi
    echo

    echo "=========================================="
    echo "Next Steps:"
    if [[ ! -f "${release_path}/${iso_base}" ]]; then
      echo "  1. Run: just release"
    elif [[ ! -f "${release_path}/${iso_base}.torrent" ]]; then
      echo "  1. Run: just release-create-torrents ${tag}"
    elif ! gh release view "${tag}" -R "${repo_organization}/${image_name}" &>/dev/null 2>&1; then
      echo "  1. Run: just release-create ${tag}"
    else
      echo "  ✓ Release workflow complete!"
      echo "  • Check seeding: just release-seed-status"
      echo "  • View release: gh release view ${tag}"
    fi

# Check all prerequisites for release workflow
[group('Release')]
release-check-prereqs:
    #!/usr/bin/env bash
    set -euo pipefail

    echo "=========================================="
    echo "Release Prerequisites Check"
    echo "=========================================="
    echo

    errors=0

    # Check podman/docker
    echo "Container Runtime:"
    if command -v podman &> /dev/null; then
      echo "  ✓ podman installed"
    elif command -v docker &> /dev/null; then
      echo "  ✓ docker installed"
    else
      echo "  ✗ Neither podman nor docker found"
      ((errors++))
    fi
    echo

    # Check gh CLI
    echo "GitHub CLI:"
    if command -v gh &> /dev/null; then
      gh_version=$(gh --version | head -1)
      echo "  ✓ ${gh_version}"

      # Check authentication
      if gh auth status &>/dev/null; then
        echo "  ✓ Authenticated"
      else
        echo "  ✗ Not authenticated - run: gh auth login"
        ((errors++))
      fi
    else
      echo "  ✗ gh not installed"
      echo "    Install: sudo rpm-ostree install gh && sudo rpm-ostree apply-live"
      ((errors++))
    fi
    echo

    # Check torrent creation tools
    echo "Torrent Creation:"
    if command -v mktorrent &> /dev/null; then
      echo "  ✓ mktorrent installed (preferred)"
    elif command -v transmission-create &> /dev/null; then
      echo "  ✓ transmission-create installed (fallback)"
    else
      echo "  ✗ No torrent creation tool found"
      echo "    Install: sudo rpm-ostree install transmission-cli"
      ((errors++))
    fi
    echo

    # Check transmission tools for seeding
    echo "Torrent Management:"
    if command -v transmission-daemon &> /dev/null; then
      echo "  ✓ transmission-daemon installed"
    else
      echo "  ℹ transmission-daemon not installed (optional for seeding)"
      echo "    Install: sudo rpm-ostree install transmission transmission-daemon"
    fi

    if command -v transmission-cli &> /dev/null; then
      echo "  ✓ transmission-cli installed"
    else
      echo "  ℹ transmission-cli not installed (optional)"
    fi

    if command -v transmission-show &> /dev/null; then
      echo "  ✓ transmission-show installed"
    else
      echo "  ✗ transmission-show not found (required for magnet links)"
      ((errors++))
    fi

    if command -v transmission-remote &> /dev/null; then
      echo "  ✓ transmission-remote installed"
    else
      echo "  ℹ transmission-remote not installed (optional for seeding)"
    fi
    echo

    # Check disk space
    echo "Disk Space:"
    available=$(df -BG . | tail -1 | awk '{print $4}' | sed 's/G//')
    echo "  Available: ${available}GB"
    if [[ $available -lt 20 ]]; then
      echo "  ⚠ Less than 20GB available (ISOs are ~17GB)"
      echo "    Consider freeing up space"
    else
      echo "  ✓ Sufficient space for ISO builds"
    fi
    echo

    # Check seeding service
    echo "Seeding Service:"
    if systemctl --user is-enabled bazzite-ai-seeding.service &>/dev/null; then
      echo "  ✓ Seeding service configured"
    else
      echo "  ℹ Seeding service not set up (optional)"
      echo "    Run: just release-setup-seeding"
    fi
    echo

    echo "=========================================="
    if [[ $errors -eq 0 ]]; then
      echo "✓ All required prerequisites met!"
      echo
      echo "Ready to run: just release"
    else
      echo "✗ ${errors} error(s) found"
      echo
      echo "Fix the errors above before running release workflow"
      exit 1
    fi

# Install required tools for release workflow (for non-immutable systems)
[group('Release')]
release-install-tools:
    #!/usr/bin/env bash
    set -euo pipefail

    echo "=========================================="
    echo "Release Tools Installation"
    echo "=========================================="
    echo
    echo "⚠️  Note: This system is running Fedora Atomic/Bazzite (immutable)"
    echo
    echo "For immutable systems, use rpm-ostree:"
    echo
    echo "  # Install all tools at once:"
    echo "  sudo rpm-ostree install gh mktorrent transmission transmission-daemon transmission-cli"
    echo
    echo "  # Apply immediately without reboot:"
    echo "  sudo rpm-ostree apply-live"
    echo
    echo "Or install individually as needed:"
    echo
    echo "  # GitHub CLI (required)"
    echo "  rpm-ostree install gh"
    echo
    echo "  # Torrent tools (required for torrents)"
    echo "  rpm-ostree install mktorrent transmission-cli"
    echo
    echo "  # Seeding tools (optional)"
    echo "  rpm-ostree install transmission transmission-daemon"
    echo
    echo "After installation, run: just release-check-prereqs"

# Verify torrent files are valid
[group('Release')]
release-verify-torrents tag=`just _release-tag`:
    #!/usr/bin/env bash
    set -euo pipefail
    tag="{{ tag }}"

    release_path="${release_dir}/${tag}"
    iso_base="${release_path}/${image_name}-${tag}.iso"
    iso_nvidia="${release_path}/${image_name}-nvidia-${tag}.iso"

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

    # Verify ISOs exist where torrents expect them
    iso_base_path="${release_path}/${iso_base}"
    iso_nvidia_path="${release_path}/${iso_nvidia}"

    if [[ ! -f "${iso_base_path}" ]]; then
      echo "✗ Base ISO not found: ${iso_base_path}"
      echo "Run 'just release-organize' first"
      exit 1
    fi

    if [[ ! -f "${iso_nvidia_path}" ]]; then
      echo "✗ NVIDIA ISO not found: ${iso_nvidia_path}"
      echo "Run 'just release-organize' first"
      exit 1
    fi

    echo "✓ ISOs verified in ${release_path}"
    echo

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

    # Get absolute path for transmission-remote
    absolute_release_path=$(cd "${release_path}" && pwd)

    # Add base torrent with download directory
    if transmission-remote -w "${absolute_release_path}" -a "${torrent_base}" 2>/dev/null; then
      echo "✓ Added ${iso_base}.torrent"
    else
      echo "ℹ ${iso_base}.torrent may already be added"
    fi

    # Add NVIDIA torrent with download directory
    if transmission-remote -w "${absolute_release_path}" -a "${torrent_nvidia}" 2>/dev/null; then
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
      echo "Tracker Status:"
      echo

      # Show tracker status for each torrent
      torrent_ids=$(transmission-remote -l | grep -E '^\s+[0-9]+' | awk '{print $1}')
      if [ -n "$torrent_ids" ]; then
        for id in $torrent_ids; do
          torrent_name=$(transmission-remote -t ${id} -i 2>/dev/null | grep "^  Name:" | cut -d: -f2- | xargs)
          if [ -n "$torrent_name" ]; then
            echo "  Torrent ${id}: ${torrent_name}"
            transmission-remote -t ${id} -it 2>/dev/null | grep -A1 "Tracker [0-9]:" | grep -v "^--$" | sed 's/^/    /'
            echo
          fi
        done
      fi

      echo "Commands:"
      echo "  Stop seeding: just release-seed-stop"
      echo "  View logs:    journalctl --user -u bazzite-ai-seeding -f"
    else
      echo "✗ Cannot connect to transmission-daemon"
      echo "Check service: systemctl --user status bazzite-ai-seeding"
    fi

# Verify torrents are ready to seed
[group('Release')]
release-seed-verify tag=`just _release-tag`:
    #!/usr/bin/env bash
    set -euo pipefail
    tag="{{ tag }}"

    release_path="${release_dir}/${tag}"

    echo "=========================================="
    echo "Verifying Seeding Readiness"
    echo "=========================================="
    echo

    # Check if service exists
    if ! systemctl --user is-enabled bazzite-ai-seeding.service &>/dev/null; then
      echo "✗ Seeding service not set up"
      echo "Run: just release-setup-seeding"
      exit 1
    fi

    # Check if service is running
    if ! systemctl --user is-active bazzite-ai-seeding.service &>/dev/null; then
      echo "✗ Seeding service not running"
      echo "Run: just release-seed-start ${tag}"
      exit 1
    fi

    echo "✓ Seeding service running"
    echo

    # Check if transmission-remote is available
    if ! command -v transmission-remote &> /dev/null; then
      echo "✗ transmission-remote not found"
      echo "Install with: sudo dnf install transmission-cli"
      exit 1
    fi

    # Check torrents are added
    torrent_count=$(transmission-remote -l 2>/dev/null | grep -c ".iso" || echo "0")
    if [ $torrent_count -lt 2 ]; then
      echo "✗ Expected 2 torrents, found ${torrent_count}"
      echo "Run: just release-seed-start ${tag}"
      exit 1
    fi

    echo "✓ Found ${torrent_count} torrent(s)"
    echo

    # Check both torrents are 100% complete
    incomplete=$(transmission-remote -l 2>/dev/null | grep ".iso" | grep -v "100%" || echo "")
    if [ -n "$incomplete" ]; then
      echo "⚠️  Some torrents not fully verified:"
      echo "$incomplete"
      echo
      echo "Wait for verification to complete or check ISO file locations"
      echo "Check with: just release-seed-status"
      exit 1
    fi

    echo "✓ All torrents verified (100% complete)"
    echo "✓ Ready to seed"
    echo

    # Show active tracker announces
    echo "Active trackers:"
    transmission-remote -t all -it 2>/dev/null | \
      grep -E "(Tracker [0-9]+:|Announce)" | \
      grep -v "will not announce" | \
      head -20

    echo
    echo "=========================================="
    echo "✅ Seeding verification passed!"
    echo "=========================================="
    echo
    echo "Next steps:"
    echo "  Monitor: just release-seed-status"
    echo "  Logs:    journalctl --user -u bazzite-ai-seeding -f"

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

# ============================================
# Documentation Commands
# ============================================

# Install Python dependencies for building docs
[group('Documentation')]
docs-install:
    #!/usr/bin/env bash
    set -euo pipefail
    if ! command -v pixi &> /dev/null; then
      echo "✗ pixi not found"
      echo
      echo "Install with: curl -fsSL https://pixi.sh/install.sh | bash"
      echo "Or visit: https://pixi.sh"
      exit 1
    fi
    echo "Installing documentation dependencies with pixi..."
    pixi install
    echo "✓ Documentation dependencies installed"

# Build HTML documentation with Jupyter Book
[group('Documentation')]
docs-build:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Building Jupyter Book documentation..."
    pixi run docs-build
    echo
    echo "✓ Documentation built successfully"
    echo
    echo "Open: docs/_build/html/index.html"

# Serve documentation locally with auto-reload
[group('Documentation')]
docs-serve:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Starting documentation server with auto-reload..."
    echo "Open: http://localhost:8000"
    echo "Press Ctrl+C to stop"
    pixi run docs-serve

# Clean documentation build artifacts
[group('Documentation')]
docs-clean:
    #!/usr/bin/env bash
    set -euxo pipefail
    pixi run docs-clean
    echo "✓ Documentation build artifacts cleaned"

# Full documentation rebuild (clean + build)
[group('Documentation')]
docs-rebuild:
    #!/usr/bin/env bash
    pixi run docs-rebuild
