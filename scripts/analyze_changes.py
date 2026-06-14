#!/usr/bin/env python3
"""Analyze changes in recipe.yaml between versions, including upstream source repo git logs."""

import argparse
import os
import subprocess
import sys

try:
    import yaml
except ImportError:
    import ruamel.yaml as yaml


def build_local_repo_map(workspace):
    """Map target_directory names to local paths under a workspace root."""
    ws = os.path.expanduser(workspace)
    return {
        "rest": os.path.join(ws, "rest"),
        "rest_tensors": os.path.join(ws, "rest_tensors"),
        "rest_libcint": os.path.join(ws, "rest_libcint"),
        "rest_regression": os.path.join(ws, "rest_regression"),
        "rest_workspace": os.path.join(ws, "rest_workspace"),
    }


def run(cmd, cwd=None, check=True):
    result = subprocess.run(cmd, capture_output=True, text=True, cwd=cwd)
    if check and result.returncode != 0:
        print(f"WARNING: {' '.join(cmd)} failed: {result.stderr.strip()}", file=sys.stderr)
    return result.stdout.strip(), result.returncode


def git_log_commits(repo_path, filepath):
    """Return list of (commit_hash, subject) for commits touching a file, oldest first."""
    out, _ = run(
        ["git", "log", "--format=%H %s", "--", filepath],
        cwd=repo_path, check=False,
    )
    if not out:
        return []
    commits = []
    for line in out.strip().split("\n"):
        parts = line.split(" ", 1)
        if len(parts) == 2:
            commits.append((parts[0], parts[1]))
        else:
            commits.append((parts[0], ""))
    commits.reverse()
    return commits


def _yaml_load(text):
    """Load YAML text, handling glob patterns and syntax quirks in old recipe files."""
    import re
    safe_text = re.sub(r'^(\s*- )(\*\*[^\s]+.*)$', r'\1"\2"', text, flags=re.MULTILINE)
    try:
        from yaml import CLoader
        return yaml.load(safe_text, Loader=CLoader)
    except Exception:
        pass
    try:
        return yaml.load(safe_text, Loader=yaml.Loader)
    except Exception:
        pass
    return None


def _extract_version_regex(text):
    """Extract package.version using regex fallback."""
    import re
    m = re.search(r'^\s*version:\s*"([^"]*)"', text, re.MULTILINE)
    if m:
        return m.group(1)
    m = re.search(r"^\s*version:\s*'([^']*)'", text, re.MULTILINE)
    if m:
        return m.group(1)
    m = re.search(r'^\s*version:\s*(\S+)', text, re.MULTILINE)
    if m:
        return m.group(1).strip('"').strip("'")
    return None


def _extract_build_regex(text):
    """Extract build.number using regex fallback."""
    import re
    m = re.search(r'^\s*number:\s*(\d+)', text, re.MULTILINE)
    if m:
        return m.group(1)
    return None


def get_recipe_build(repo_path, commit_hash):
    """Extract build number from recipe.yaml at a given commit. Returns string or None."""
    out, rc = run(
        ["git", "show", f"{commit_hash}:recipe_rattler/recipe.yaml"],
        cwd=repo_path, check=False,
    )
    if rc != 0:
        return None
    parsed = _yaml_load(out)
    if parsed is not None:
        return str(parsed.get("build", {}).get("number", ""))
    return _extract_build_regex(out)


def _extract_sources_regex(text):
    """Extract source repos using regex fallback. Returns list of {td, git_url, rev, tag}."""
    import re
    repos = []
    blocks = re.split(r'\n(?:  )?- git:', text)
    for block in blocks[1:]:
        git_url_m = re.search(r'^\s*git:\s*(\S+)', block, re.MULTILINE)
        if not git_url_m:
            continue
        git_url = git_url_m.group(1)
        rev_m = re.search(r'^\s*rev:\s*(\S+)', block, re.MULTILINE)
        tag_m = re.search(r'^\s*tag:\s*(\S+)', block, re.MULTILINE)
        td_m = re.search(r'^\s*target_directory:\s*(\S+)', block, re.MULTILINE)
        td = td_m.group(1) if td_m else git_url.rstrip("/").split("/")[-1].replace(".git", "")
        repos.append({
            "target_directory": td,
            "git_url": git_url,
            "rev": rev_m.group(1) if rev_m else None,
            "tag": tag_m.group(1) if tag_m else None,
        })
    return repos


def get_recipe_at_commit(repo_path, commit_hash):
    """Extract recipe.yaml content at a given commit. Returns (version, sources) tuple or None."""
    out, rc = run(
        ["git", "show", f"{commit_hash}:recipe_rattler/recipe.yaml"],
        cwd=repo_path, check=False,
    )
    if rc != 0:
        return None
    parsed = _yaml_load(out)
    if parsed is not None:
        version = parsed.get("package", {}).get("version")
        sources = []
        raw_sources = parsed.get("source", [])
        if not isinstance(raw_sources, list):
            raw_sources = [raw_sources]
        for s in raw_sources:
            if "git" not in s:
                continue
            git_url = s["git"]
            td = s.get("target_directory", git_url.rstrip("/").split("/")[-1].replace(".git", ""))
            rev = s.get("rev")
            tag = s.get("tag")
            sources.append({"target_directory": td, "git_url": git_url, "rev": rev, "tag": tag})
        return version, sources

    version = _extract_version_regex(out)
    sources = _extract_sources_regex(out)
    if version is None:
        return None
    return version, sources


def get_recipe_version(repo_path, commit_hash):
    """Extract only the version from recipe.yaml at a given commit. Returns version string or None."""
    out, rc = run(
        ["git", "show", f"{commit_hash}:recipe_rattler/recipe.yaml"],
        cwd=repo_path, check=False,
    )
    if rc != 0:
        return None
    return _extract_version_regex(out)


def get_recipe_sources(repo_path, commit_hash):
    """Extract just the source list from recipe.yaml at a given commit."""
    out, rc = run(
        ["git", "show", f"{commit_hash}:recipe_rattler/recipe.yaml"],
        cwd=repo_path, check=False,
    )
    if rc != 0:
        return []
    parsed = _yaml_load(out)
    if parsed is not None:
        sources = parsed.get("source", [])
        if not isinstance(sources, list):
            sources = [sources]
        result = []
        for s in sources:
            if "git" not in s:
                continue
            git_url = s["git"]
            td = s.get("target_directory", git_url.rstrip("/").split("/")[-1].replace(".git", ""))
            result.append({"target_directory": td, "git_url": git_url, "rev": s.get("rev"), "tag": s.get("tag")})
        return result
    return _extract_sources_regex(out)


def find_version_transitions(repo_path):
    """Walk commits that touched recipe.yaml and find where package.version changed."""
    commits = git_log_commits(repo_path, "recipe_rattler/recipe.yaml")
    transitions = []
    last_version = None
    last_commit = None
    last_build = None
    for chash, subject in commits:
        version = get_recipe_version(repo_path, chash)
        if version is None:
            continue
        build = get_recipe_build(repo_path, chash)
        if last_version is not None and version != last_version:
            transitions.append({
                "from_version": last_version,
                "from_build": last_build,
                "from_commit": last_commit,
                "to_version": version,
                "to_build": build,
                "to_commit": chash,
            })
        last_version = version
        last_build = build
        last_commit = chash
    return transitions


def compare_sources(repos_a, repos_b):
    """Compare two source-repo lists. Returns dicts for changed, added, removed."""
    changed = []
    added = []
    removed = []

    map_a = {r["target_directory"]: r for r in repos_a}
    map_b = {r["target_directory"]: r for r in repos_b}

    all_dirs = set(map_a.keys()) | set(map_b.keys())
    for d in sorted(all_dirs):
        ra = map_a.get(d)
        rb = map_b.get(d)
        if ra is None and rb is not None:
            added.append(rb)
        elif rb is None and ra is not None:
            removed.append(ra)
        elif ra["rev"] != rb["rev"] or ra["tag"] != rb["tag"]:
            changed.append((ra, rb))

    return changed, added, removed


def fetch_repo(local_path):
    """Fetch from origin; returns True on success."""
    if local_path is None or not os.path.isdir(local_path):
        return False
    out, rc = run(["git", "fetch", "origin"], cwd=local_path, check=False)
    return rc == 0


def get_log_between(local_path, old_rev, new_rev):
    """Get git log --oneline between two revs. Returns list of strings."""
    if local_path is None or not os.path.isdir(local_path):
        return [f"  [local repo not found at {local_path}]"]
    out, rc = run(
        ["git", "log", "--oneline", f"{old_rev}..{new_rev}"],
        cwd=local_path, check=False,
    )
    if rc != 0:
        return [f"  [failed to query git log: {out}]"]
    if not out.strip():
        return ["  (no commits between these revs)"]
    return [f"  {line}" for line in out.strip().split("\n")]


def format_recipe_diff(repo_path, from_commit, to_commit):
    """Return the diff of recipe.yaml between two commits as a list of strings."""
    out, rc = run(
        ["git", "diff", f"{from_commit}..{to_commit}", "--", "recipe_rattler/recipe.yaml"],
        cwd=repo_path, check=False,
    )
    if rc != 0 or not out.strip():
        return []
    return out.strip().split("\n")


def print_summary(transition, recipe_diff_lines, source_changes, no_fetch, full_diff, local_repo_map):
    """Print a formatted summary of one version transition."""
    print()
    print("=" * 72)
    from_str = f"v{transition['from_version']} (build {transition.get('from_build', '?')})"
    to_str = f"v{transition['to_version']} (build {transition.get('to_build', '?')})"
    print(f"  {from_str}  →  {to_str}")
    print(f"  {transition['from_commit'][:8]}  →  {transition['to_commit'][:8]}")
    print("=" * 72)

    changed, added, removed = source_changes

    if changed:
        print(f"\n┌─ Repos with changed revisions ({len(changed)}):")
        for old_r, new_r in changed:
            td = new_r["target_directory"]
            print(f"│  {td}")
            print(f"│    old rev: {old_r['rev']}")
            print(f"│    new rev: {new_r['rev']}")
            local_path = local_repo_map.get(td)
            if not no_fetch:
                fetch_repo(local_path)
            log_lines = get_log_between(local_path, old_r["rev"], new_r["rev"])
            print(f"│    commits ({len(log_lines)}):")
            for line in log_lines:
                print(f"│      {line}")
            print(f"│")
        print(f"└─")
    else:
        print("\n  (no source repos changed revision)")

    if added:
        print(f"\n┌─ New repos added ({len(added)}):")
        for r in added:
            print(f"│  {r['target_directory']}  rev={r.get('rev')}  tag={r.get('tag')}")
        print(f"└─")

    if removed:
        print(f"\n┌─ Repos removed ({len(removed)}):")
        for r in removed:
            print(f"│  {r['target_directory']}  rev={r.get('rev')}  tag={r.get('tag')}")
        print(f"└─")

    if full_diff and recipe_diff_lines:
        print(f"\n┌─ Recipe diff:")
        for line in recipe_diff_lines:
            print(f"│ {line}")
        print(f"└─")

    print()


def main():
    parser = argparse.ArgumentParser(
        description="Analyze recipe.yaml changes between versions, including upstream git logs."
    )
    parser.add_argument("--from", dest="from_version", help="Old version (e.g. 2026.1.0)")
    parser.add_argument("--to", dest="to_version", help="New version (e.g. 2026.1.0.1)")
    parser.add_argument("--auto", action="store_true", help="Auto-discover and print all version transitions")
    parser.add_argument("--no-fetch", action="store_true", help="Skip fetching local source repos")
    parser.add_argument("--full", action="store_true", help="Include full recipe.yaml diff")
    parser.add_argument("--workspace", default="~/rest_workspace",
                        help="Path to workspace containing source repos (default: ~/rest_workspace)")
    parser.add_argument(
        "--repo-path", default=os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        help="Path to feedstock repo (default: parent of this script's directory)"
    )
    args = parser.parse_args()

    repo_path = os.path.abspath(args.repo_path)
    if not os.path.isdir(os.path.join(repo_path, ".git")):
        print(f"ERROR: {repo_path} is not a git repository", file=sys.stderr)
        sys.exit(1)

    local_repo_map = build_local_repo_map(args.workspace)

    transitions = find_version_transitions(repo_path)

    if not transitions:
        print("No version transitions found in recipe.yaml history.")
        sys.exit(0)

    if args.auto:
        for tr in transitions:
            repos_a = get_recipe_sources(repo_path, tr["from_commit"])
            repos_b = get_recipe_sources(repo_path, tr["to_commit"])
            source_changes = compare_sources(repos_a, repos_b)
            diff_lines = format_recipe_diff(repo_path, tr["from_commit"], tr["to_commit"])
            print_summary(tr, diff_lines, source_changes, args.no_fetch, args.full, local_repo_map)
        return

    if args.from_version or args.to_version:
        if not args.from_version or not args.to_version:
            print("ERROR: both --from and --to are required", file=sys.stderr)
            sys.exit(1)

        from_commit = None
        to_commit = None
        commits = git_log_commits(repo_path, "recipe_rattler/recipe.yaml")
        commits.reverse()
        for chash, _ in commits:
            version = get_recipe_version(repo_path, chash)
            if version == args.from_version and from_commit is None:
                from_commit = chash
            if version == args.to_version and to_commit is None:
                to_commit = chash

        if from_commit is None:
            print(f"ERROR: version {args.from_version} not found in git history", file=sys.stderr)
            sys.exit(1)
        if to_commit is None:
            print(f"ERROR: version {args.to_version} not found in git history", file=sys.stderr)
            sys.exit(1)

        repos_a = get_recipe_sources(repo_path, from_commit)
        repos_b = get_recipe_sources(repo_path, to_commit)
        source_changes = compare_sources(repos_a, repos_b)
        diff_lines = format_recipe_diff(repo_path, from_commit, to_commit)

        transition = {
            "from_version": args.from_version,
            "from_build": get_recipe_build(repo_path, from_commit),
            "from_commit": from_commit,
            "to_version": args.to_version,
            "to_build": get_recipe_build(repo_path, to_commit),
            "to_commit": to_commit,
        }
        print_summary(transition, diff_lines, source_changes, args.no_fetch, args.full, local_repo_map)
        return

    parser.print_help()


if __name__ == "__main__":
    main()
