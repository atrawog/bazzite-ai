# Semantic Commit Message Migration Guide

**Date:** 2025-10-25
**Status:** Active
**Affects:** All contributors

## Overview

Bazzite AI has implemented **strict semantic commit message enforcement** to improve git history readability, enable automated workflows, and ensure consistent contribution standards.

All commits and PR titles must now follow the semantic commit message convention with one of six allowed prefixes.

## What Changed

### Enforced Validation

**New Requirements:**
1. **PR titles** must follow semantic format
2. **All commits** in PRs must follow semantic format
3. **All pushes** to any branch are validated
4. **Automated CI/CD** triggers based on commit type

**Enforcement Mechanism:**
- GitHub Actions workflows validate all commits and PR titles
- Failed validation **blocks PR merging** (required status checks)
- Works across all branches (not just main)

### Allowed Prefixes

**ONLY these six prefixes are allowed:**

| Prefix | Purpose | Example |
|--------|---------|---------|
| `Fix:` | Bug fixes | `Fix: correct path handling in build script` |
| `Feat:` | New features | `Feat: add GPU support for containers` |
| `Docs:` | Documentation | `Docs: update installation guide` |
| `Chore:` | Maintenance | `Chore: update dependencies to latest` |
| `Refactor:` | Code refactoring | `Refactor: simplify build cache logic` |
| `Style:` | Code formatting | `Style: format justfiles properly` |

**Note:** Prefixes are **case-sensitive** and must be followed by a colon and space.

## Legacy Prefix Migration

The repository previously used additional prefixes that are no longer allowed for **new commits**:

### Migration Table

| Legacy Prefix | New Prefix | Reasoning |
|--------------|------------|-----------|
| `Add:` | `Feat:` | Adding new functionality is a feature |
| `Update:` | `Feat:` or `Chore:` | Features → `Feat:`, Dependencies/config → `Chore:` |
| `Optimize:` | `Refactor:` | Performance improvements are refactoring |
| `Report:` | `Docs:` | Reports are documentation |

### Examples of Legacy → New

**Legacy commits (grandfathered in, don't modify):**
```
Add: Pixi environment configuration for documentation builds
Update: Documentation build system to use pixi
Optimize: Fix cache invalidation + broken ujust imports
Report: Final comprehensive container testing report
```

**How they should be written now:**
```
Feat: add Pixi environment configuration for documentation builds
Chore: update documentation build system to use pixi
Refactor: fix cache invalidation and broken ujust imports
Docs: final comprehensive container testing report
```

### Handling Existing Commits

**DO NOT rewrite git history** to fix legacy commits. They are grandfathered in and preserved for historical accuracy.

**Only apply the new convention** to commits created after 2025-10-25.

## Automated Workflow Changes

Commit prefixes now trigger specific CI/CD behaviors:

### Build Workflow (`build.yml`)

**Triggers full build:**
- `Feat:` - New features need testing
- `Fix:` - Bug fixes need validation
- `Refactor:` - Code changes need verification
- `Style:` - Formatting changes need linting

**Skips build on feature branches:**
- `Docs:` only commits - No code changes
- `Chore:` only commits - Maintenance doesn't affect runtime

**Always builds on main branch** regardless of commit type (production readiness).

### Documentation Workflow (`docs.yml`)

**Triggers docs build:**
- Changes to `docs/` directory
- Changes to `pixi.toml`, `pixi.lock`
- **Any commit with `Docs:` prefix** (even if no docs files changed)

This allows documentation updates to be triggered via commit message.

### CI Skip Detection (`ci-skip.yml`)

Automatically detects PRs with only `Docs:` or `Chore:` commits and reports skip eligibility.

## How to Adapt

### For Active PRs

If you have an **open PR** that fails validation:

#### Fix PR Title

1. Edit the PR title on GitHub
2. Ensure it starts with one of the six allowed prefixes
3. Validation re-runs automatically

#### Fix Commit Messages

**Option 1: Interactive Rebase (Recommended)**

```bash
# Start interactive rebase
git rebase -i HEAD~N  # N = number of commits to fix

# In the editor, change "pick" to "reword" for commits to fix
# Save and close

# Git will prompt for new messages - use semantic format
# Example: Change "Updated docs" → "Docs: update installation guide"

# Force push (safe with --force-with-lease)
git push --force-with-lease
```

**Option 2: Squash All Commits**

```bash
# Reset to base branch
git reset --soft origin/main

# Create new commit with semantic message
git commit -m "Feat: your feature description here"

# Force push
git push --force-with-lease
```

**Option 3: Amend Last Commit**

```bash
# If only last commit needs fixing
git commit --amend -m "Fix: correct commit message format"
git push --force-with-lease
```

### For New Work

**Always use semantic prefixes from the start:**

```bash
# Good examples
git commit -m "Feat: add WinBoat Windows app support"
git commit -m "Fix: devcontainers-cli false installation error"
git commit -m "Docs: add comprehensive container usage guide"
git commit -m "Chore: update base image to stable-42.20251022"
git commit -m "Refactor: split package installation into stability layers"
git commit -m "Style: fix justfile indentation consistency"

# Bad examples (will fail validation)
git commit -m "added new feature"        # No prefix
git commit -m "Add: new feature"         # Legacy prefix
git commit -m "fix: typo"                # Lowercase
git commit -m "Fix documentation"        # Missing colon
```

### Choosing the Right Prefix

**Decision tree:**

1. **Did you fix a bug?** → `Fix:`
2. **Did you add a new feature or capability?** → `Feat:`
3. **Did you change documentation only?** → `Docs:`
4. **Did you update dependencies, configs, or do maintenance?** → `Chore:`
5. **Did you refactor code without changing behavior?** → `Refactor:`
6. **Did you only change code formatting or style?** → `Style:`

**When in doubt:**
- New functionality = `Feat:`
- Fixing something broken = `Fix:`
- Everything else = likely `Chore:` or `Refactor:`

## Validation Details

### Workflows

**`.github/workflows/semantic-pr.yml`**
- Uses `amannn/action-semantic-pull-request@v6`
- Validates PR title format
- Runs on: `pull_request_target`
- Required status check

**`.github/workflows/semantic-commits.yml`**
- Custom bash script validation
- Validates all commits in PR or push
- Runs on: `push`, `pull_request` (all branches)
- Required status check

**`.github/workflows/ci-skip.yml`**
- Detects Docs/Chore only PRs
- Reports skip eligibility for optimization
- Informational only (not blocking)

### Error Messages

If validation fails, you'll see detailed error messages:

```
ERROR: Found 2 commit(s) with invalid format

Invalid commits:
  - abc1234: updated readme
  - def5678: Add new feature

Required format: <Type>: <description>

Allowed types:
  Fix:      Bug fixes
  Feat:     New features
  Docs:     Documentation changes
  Chore:    Maintenance, dependencies, config
  Refactor: Code refactoring
  Style:    Code formatting, style changes

Examples:
  ✓ Fix: correct path handling in build script
  ✓ Feat: add GPU support for containers
  ...
```

The error message includes instructions for fixing your commits.

## Branch Protection

The `main` branch now requires:
1. ✅ semantic-pr validation to pass
2. ✅ semantic-commits validation to pass
3. ✅ build workflow to pass (unless Docs/Chore only)

PRs cannot be merged until all required checks pass.

## Benefits

### For Contributors

1. **Clear intent** - Commit type immediately shows what changed
2. **Better reviews** - Reviewers can quickly understand change scope
3. **Searchable history** - Easy to find specific types of changes
4. **Guided workflow** - Clear rules reduce ambiguity

### For the Project

1. **Automated workflows** - Intelligent CI/CD based on commit type
2. **Release automation** - Can generate changelogs automatically
3. **Resource optimization** - Skip expensive builds when not needed
4. **Professional standards** - Industry-standard practice

## Resources

- **CONTRIBUTING.md** - Full contribution guidelines
- **CLAUDE.md** - Quick reference and project documentation
- **Conventional Commits** - https://www.conventionalcommits.org/
- **Semantic PR Action** - https://github.com/amannn/action-semantic-pull-request

## Questions?

If you have questions about the semantic commit convention:

1. Read [CONTRIBUTING.md](../../CONTRIBUTING.md) for detailed examples
2. Open a [GitHub Discussion](https://github.com/atrawog/bazzite-ai/discussions)
3. Ask in your PR comments - maintainers will help!

## Timeline

- **2025-10-25**: Semantic commit enforcement implemented
- **Existing commits**: Grandfathered in, no changes required
- **New commits**: Must follow new convention
- **Open PRs**: Must fix validation to merge

---

**Thank you for adapting to the new convention!** This improvement helps make Bazzite AI more maintainable and professional.
