import os
import pathlib
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
if os.name == "nt":
    candidates = []
    bash_env = os.environ.get("BASH")
    if bash_env:
        candidates.append(pathlib.Path(bash_env))
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
        normalized_candidate = candidate_str.replace("/", "\\")
        if normalized_candidate.endswith(r"\windows\system32\bash.exe"):
            continue
        if r"\library\usr\bin\bash.exe" in normalized_candidate:
            preferred_where.append(candidate)
        else:
            fallback_where.append(candidate)
    candidates.extend(preferred_where)
    candidates.extend(fallback_where)
    build_prefix = os.environ.get("BUILD_PREFIX")
    # Ignore unresolved cmd-style placeholders like "%BUILD_PREFIX%".
    if build_prefix and build_prefix.strip() and build_prefix.strip() != "%BUILD_PREFIX%":
        candidates.append(pathlib.Path(build_prefix) / "Library" / "usr" / "bin" / "bash.exe")
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

try:
    subprocess.run([bash_cmd, str(script)], check=True)
except FileNotFoundError as exc:
    raise RuntimeError(f"Failed to execute build script: bash not found ({bash_cmd}). Ensure bash is installed and available in PATH.") from exc
except subprocess.CalledProcessError as exc:
    raise RuntimeError(f"Failed to execute build script: build.sh exited with code {exc.returncode}") from exc
