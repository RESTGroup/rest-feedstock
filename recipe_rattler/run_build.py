import os
import pathlib
import re
import shutil
import subprocess


recipe_dir = os.environ.get("RECIPE_DIR")
if not recipe_dir:
    raise RuntimeError("RECIPE_DIR is not set")

script = pathlib.Path(recipe_dir) / "build.sh"
if not script.is_file():
    raise FileNotFoundError(f"Build script not found: {script}")

print(f"Running build script: {script}")

bash_cmd = "bash"
run_env = os.environ.copy()
run_cwd = None


def _is_unresolved_placeholder(value: str) -> bool:
    if not value:
        return False
    stripped = value.strip()
    return bool(re.fullmatch(r"%[^%]+%", stripped) or re.fullmatch(r"\$\{[^}]+\}", stripped))


if os.name == "nt":
    critical_env_vars = ("SRC_DIR", "PREFIX", "BUILD_PREFIX")
    unresolved = []
    for env_name in ("RECIPE_DIR", *critical_env_vars):
        value = run_env.get(env_name, "")
        expanded = os.path.expandvars(value) if value else value
        run_env[env_name] = expanded
        if env_name in critical_env_vars and _is_unresolved_placeholder(expanded):
            unresolved.append((env_name, value))
    if unresolved:
        unresolved_text = ", ".join(f"{name}={raw!r}" for name, raw in unresolved)
        raise RuntimeError(
            "Windows build environment variables were not expanded before running build.sh. "
            f"Unresolved placeholders: {unresolved_text}"
        )
    src_dir = run_env.get("SRC_DIR", "").strip()
    if src_dir:
        src_dir_path = pathlib.Path(src_dir)
        if src_dir_path.is_dir():
            run_cwd = str(src_dir_path)

    candidates = []
    bash_env = os.environ.get("BASH")
    if bash_env:
        candidates.append(pathlib.Path(bash_env))
    build_prefix = run_env.get("BUILD_PREFIX")
    build_prefix_stripped = build_prefix.strip() if build_prefix else ""
    if build_prefix_stripped and build_prefix_stripped != "%BUILD_PREFIX%":
        candidates.append(pathlib.Path(build_prefix) / "Library" / "usr" / "bin" / "bash.exe")
    try:
        where_bash = subprocess.check_output(["where", "bash"], encoding="utf-8", errors="ignore")
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("Warning: failed to query bash paths via `where bash`; continuing with fallback candidates.")
        where_bash = ""
    preferred_where = []
    fallback_where = []
    for line in where_bash.splitlines():
        candidate = pathlib.Path(line.strip())
        candidate_str = str(candidate).lower()
        if not candidate_str:
            continue
        normalized_candidate = os.path.normpath(candidate_str).replace("/", "\\")
        if normalized_candidate.endswith(r"\windows\system32\bash.exe"):
            continue
        if r"\library\usr\bin\bash.exe" in normalized_candidate:
            preferred_where.append(candidate)
        else:
            fallback_where.append(candidate)
    candidates.extend(preferred_where)
    pf_values = [
        os.environ.get("ProgramW6432"),
        os.environ.get("ProgramFiles"),
        os.environ.get("ProgramFiles(x86)"),
    ]
    seen = set()
    for pf in pf_values:
        if not pf:
            continue
        if pf in seen:
            continue
        seen.add(pf)
        candidates.append(pathlib.Path(pf) / "Git" / "bin" / "bash.exe")
    candidates.extend(fallback_where)
    seen_candidates = set()
    for candidate in candidates:
        candidate_key = str(candidate).lower()
        if candidate_key in seen_candidates:
            continue
        seen_candidates.add(candidate_key)
        if candidate.is_file():
            bash_cmd = str(candidate)
            break
    else:
        bash_in_path = shutil.which("bash")
        if not bash_in_path:
            raise RuntimeError(
                "Failed to execute build script: no bash executable was found in known locations or PATH."
            )
        bash_cmd = bash_in_path

print(f"Using bash executable: {bash_cmd}")

try:
    subprocess.run([bash_cmd, str(script)], check=True, env=run_env, cwd=run_cwd)
except FileNotFoundError as exc:
    raise RuntimeError(f"Failed to execute build script: bash not found ({bash_cmd}). Ensure bash is installed and available in PATH.") from exc
except subprocess.CalledProcessError as exc:
    raise RuntimeError(f"Failed to execute build script: build.sh exited with code {exc.returncode}") from exc
