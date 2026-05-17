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
    build_prefix = os.environ.get("BUILD_PREFIX")
    if build_prefix:
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
    for candidate in candidates:
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
