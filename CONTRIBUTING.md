# Contributing to Bazzite AI

Thank you for your interest in contributing to Bazzite AI! This document provides guidelines and conventions for contributing to the project.

## Table of Contents

- [Commit Message Convention](#commit-message-convention)
- [Pull Request Process](#pull-request-process)
- [Development Workflow](#development-workflow)
- [Automated CI/CD](#automated-cicd)
- [Getting Help](#getting-help)

## Commit Message Convention

Bazzite AI uses **semantic commit messages** to maintain a clean, readable git history and enable automated workflows. All commits and PR titles **must** follow this convention.

### Required Format

```
<Type>: <description>

[optional body]

[optional footer]
```

The **type** and **colon** are mandatory. The description must be concise and clear.

### Allowed Types

| Type | Purpose | Example | Triggers |
|------|---------|---------|----------|
| `Fix:` | Bug fixes, corrections | `Fix: correct path handling in build script` | Full CI build |
| `Feat:` | New features, enhancements | `Feat: add GPU support for containers` | Full CI build |
| `Docs:` | Documentation changes | `Docs: update installation guide` | Documentation build only |
| `Chore:` | Maintenance, dependencies, configs | `Chore: update pixi dependencies to latest` | Skip CI on feature branches |
| `Refactor:` | Code refactoring, no behavior change | `Refactor: simplify build cache logic` | Full CI build |
| `Style:` | Code formatting, whitespace | `Style: format justfiles with proper indentation` | Linting only |

### Examples

**Good Examples:**

```
Fix: correct all paths for non-monorepo structure

The previous paths assumed a monorepo structure, but this
repository is standalone. Updated all references to use
correct relative paths.

Closes #42
```

```
Feat: add nvidia-container-toolkit to all variants

- Installs nvidia-container-toolkit in all KDE variants
- Enables GPU container support by default
- Updates documentation with setup instructions
```

```
Docs: upgrade Jupyter Book 1.x → 2.0 (beta 3)

Migrates documentation system to Jupyter Book 2.0 pre-release
for improved MyST Markdown support and faster builds.
```

```
Chore: update base image to bazzite stable-42.20251022
```

```
Refactor: split package installation into stability layers
```

```
Style: fix justfile indentation consistency
```

**Bad Examples:**

```
✗ updated readme
  Missing type prefix, not descriptive

✗ Add: new feature for containers
  "Add:" is not an allowed type (use "Feat:")

✗ fix: typo in docs
  Lowercase type (must be capitalized: "Fix:")

✗ Fix documentation
  Missing colon after type

✗ feat(containers): add GPU support
  Scopes in parentheses not used in this project
```

### Migration from Legacy Prefixes

If you see commits with these legacy prefixes, they are grandfathered in. **New commits must use the standard types above.**

| Legacy | New Type | Reasoning |
|--------|----------|-----------|
| `Add:` | `Feat:` | Adding new functionality |
| `Update:` | `Feat:` or `Chore:` | Feat for features, Chore for dependencies |
| `Optimize:` | `Refactor:` | Performance improvements |
| `Report:` | `Docs:` | Documentation and reports |

## Pull Request Process

### PR Title Requirements

PR titles **must** follow the same semantic commit convention. The PR title becomes the commit message when squash-merging.

**Examples:**
- `Feat: add WinBoat Windows app support`
- `Fix: devcontainers-cli false installation error`
- `Docs: add comprehensive container usage guide`

### PR Description

Include:
1. **Summary** - What changes does this PR introduce?
2. **Motivation** - Why is this change needed?
3. **Testing** - How was this tested?
4. **Screenshots** - If applicable (UI changes)
5. **Related Issues** - Link to GitHub issues if applicable

### Validation Checks

All PRs must pass these automated checks before merging:

1. **semantic-pr** - Validates PR title format
2. **semantic-commits** - Validates all commit messages in the PR
3. **build** - Builds container images (skipped for Docs/Chore only PRs)
4. **docs** - Builds documentation (for Docs: commits or docs/ changes)

**These are required status checks** - PRs cannot be merged until they pass.

### Fixing Failed Validation

If your PR fails semantic validation:

#### Fix PR Title
1. Edit the PR title on GitHub
2. Validation re-runs automatically

#### Fix Commit Messages

**Option 1: Interactive Rebase (Recommended)**
```bash
# Start interactive rebase
git rebase -i HEAD~N  # N = number of commits to edit

# In the editor, change "pick" to "reword" for commits to fix
# Save and close - git will prompt for new commit messages

# Force push (safe with --force-with-lease)
git push --force-with-lease
```

**Option 2: Amend Last Commit**
```bash
# If only the last commit needs fixing
git commit --amend -m "Fix: correct commit message format"
git push --force-with-lease
```

**Option 3: Squash and Rewrite**
```bash
# Squash all commits and rewrite with correct message
git reset --soft origin/main
git commit -m "Feat: your feature description here"
git push --force-with-lease
```

## Pre-commit Hooks and Linting

Bazzite AI uses pre-commit hooks to validate code quality locally before commits reach CI.

### Quick Start

```bash
# One-time setup (installs everything)
ujust install-dev-environment

# Or step-by-step:
ujust install-pixi          # 1. Package manager
ujust install-linters       # 2. Linting tools
ujust lint-install          # 3. Enable hooks
```

### What Gets Validated

- **Shell scripts** (*.sh): ShellCheck
- **Markdown** (*.md): markdownlint
- **YAML** (*.yml, *.yaml): yamllint
- **TOML** (*.toml): taplo
- **Justfiles**: Syntax checking
- **Commit messages**: Semantic prefix validation
- **Whitespace**: Trailing spaces, EOF newlines

### Daily Workflow

```bash
# Check all files
ujust lint

# Check staged files only
ujust lint-staged

# Auto-fix issues
ujust lint-fix

# Update hooks
ujust lint-update
```

Hooks run automatically on `git commit`.

### When Validation Fails

1. Read error message
2. Fix issues (or run `ujust lint-fix`)
3. Stage changes: `git add`
4. Retry: `git commit`

**Example:**
```bash
$ git commit -m "added new feature"
❌ ERROR: Commit message doesn't follow semantic convention

# Fix it:
$ git commit -m "Feat: add new feature"
✓ Passed all checks
```

### Bypassing (Emergency Only)

```bash
git commit --no-verify -m "Emergency fix"
```

**Warning:** May cause CI failures.

### Requirements

Pre-installed in bazzite-ai:
- ShellCheck (system)
- yamllint (system)
- nodejs20 (for npm)
- cargo/rust (for taplo)

User-installed via ujust:
- pixi (Python environment)
- markdownlint-cli (npm)
- taplo (cargo)
- pre-commit (pixi)

## Development Workflow

### Setting Up

1. **Fork and Clone**
   ```bash
   git clone https://github.com/YOUR-USERNAME/bazzite-ai.git
   cd bazzite-ai/bazzite-ai
   ```

2. **Create Feature Branch**
   ```bash
   git checkout -b feat/your-feature-name
   ```

3. **Make Changes**
   - Follow project structure in `CLAUDE.md`
   - Test locally using `just` commands
   - Update documentation if needed

4. **Commit with Semantic Messages**
   ```bash
   git add .
   git commit -m "Feat: add your feature description"
   ```

5. **Push and Create PR**
   ```bash
   git push origin feat/your-feature-name
   # Create PR on GitHub with semantic title
   ```

### Local Testing

**Build Container Image:**
```bash
just build
```

**Build VM Image:**
```bash
just build-vm
```

**Test Documentation:**
```bash
just docs-build
just docs-serve
```

**Test ujust Commands:**
```bash
# Use test wrapper (no system modifications)
./testing/ujust-test <command>

# See testing/README.md for full testing guide
```

### Code Style

- **Shell Scripts**: Use shellcheck for validation
- **Just Recipes**: Follow existing indentation (tabs, 4 spaces)
- **YAML**: 2-space indentation, no tabs
- **Markdown**: Use MyST Markdown for documentation (see `docs/`)

## Automated CI/CD

Bazzite AI uses intelligent CI/CD workflows based on commit types:

### Build Workflow (`build.yml`)

**Triggers:**
- Push to `main` - Always builds (production readiness)
- Pull requests - Builds if contains `Feat:`, `Fix:`, `Refactor:`, or `Style:` commits
- Skips for Docs/Chore only PRs on feature branches

**What it builds:**
- Container image (`bazzite-ai`)
- Development containers (`bazzite-ai-container`, `bazzite-ai-container-nvidia`)
- Pushes to GHCR
- Signs images with cosign

**Build time:** 6-8 minutes (first build), 30-60 seconds (incremental config changes)

### Documentation Workflow (`docs.yml`)

**Triggers:**
- Changes to `docs/`, `pixi.toml`, `pixi.lock`, or workflow file
- Any commit with `Docs:` prefix (even if no docs files changed)

**What it does:**
- Builds Jupyter Book documentation
- Deploys to GitHub Pages: https://atrawog.github.io/bazzite-ai/

**Build time:** 18-30 seconds

### Semantic Validation Workflows

**`semantic-pr.yml`** - Validates PR titles
**`semantic-commits.yml`** - Validates all commits in PR/push
**`ci-skip.yml`** - Detects Docs/Chore only PRs for optimization

All run on every PR and push to any branch.

## Getting Help

- **Questions**: Open a [GitHub Discussion](https://github.com/atrawog/bazzite-ai/discussions)
- **Bugs**: Open a [GitHub Issue](https://github.com/atrawog/bazzite-ai/issues)
- **Development Guide**: See `CLAUDE.md` for comprehensive project documentation
- **Container Usage**: See `docs/CONTAINER.md`
- **Release Process**: See `docs/ISO-BUILD.md`

## Branch Protection

The `main` branch has these protections:
- Requires semantic PR title validation to pass
- Requires semantic commit validation to pass
- Requires build workflow to pass (unless Docs/Chore only)
- No force pushes allowed
- No deletion allowed

## Code of Conduct

Be respectful, inclusive, and collaborative. We're building this together!

## License

By contributing, you agree that your contributions will be licensed under the same license as the project (Apache-2.0).

---

**Thank you for contributing to Bazzite AI!**

If you have questions about these guidelines, please open a discussion on GitHub.
