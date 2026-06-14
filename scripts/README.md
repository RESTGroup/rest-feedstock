# analyze_changes.py

Analyze what changed in `recipe_rattler/recipe.yaml` between feedstock versions,
including upstream source repo git logs queried from local clones.

## Usage

```bash
# Compare two specific versions (with git logs from local repos)
python3 scripts/analyze_changes.py --from 2026.1.0 --to 2026.1.0.1

# Auto-discover and print all version transitions
python3 scripts/analyze_changes.py --auto

# Skip git fetch (use cached local repo state)
python3 scripts/analyze_changes.py --from 2026.1.0 --to 2026.1.0.1 --no-fetch

# Include full recipe.yaml diff
python3 scripts/analyze_changes.py --from 2025.02.7 --to 2026.1.0 --full

# Custom source repo workspace path
python3 scripts/analyze_changes.py --auto --workspace /path/to/rest_workspace
```

## Options

| Flag | Description |
|------|-------------|
| `--from VERSION` | Old version to compare from |
| `--to VERSION` | New version to compare to |
| `--auto` | Auto-discover all version transitions from git history |
| `--no-fetch` | Skip `git fetch origin` on local source repos |
| `--full` | Include full `recipe.yaml` diff in output |
| `--workspace PATH` | Path to workspace with source repos (default: `~/rest_workspace`) |
| `--repo-path PATH` | Path to feedstock repo (default: auto-detected) |

## How It Works

1. Reads git log of `recipe_rattler/recipe.yaml` to find where `package.version` changes
2. For each version pair, parses the `source:` section to compare git revisions
3. Maps `target_directory` names to local paths under `--workspace`
4. Fetches origin, then runs `git log --oneline <old_rev>..<new_rev>` for each changed repo
5. Outputs a formatted summary: changed repos, old/new revisions, commit list, and optional recipe diff

## Expected Workspace Layout

```
~/rest_workspace/
├── rest/            # rest source repo
├── rest_tensors/    # rest_tensors source repo
├── rest_libcint/    # rest_libcint source repo
└── rest_regression/ # rest_regression source repo
```

Each directory should be a git clone tracking the corresponding upstream repo.
