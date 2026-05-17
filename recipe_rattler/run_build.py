import os
import pathlib
import subprocess


recipe_dir = os.environ.get("RECIPE_DIR")
if not recipe_dir:
    raise RuntimeError("RECIPE_DIR is not set")

script = pathlib.Path(recipe_dir) / "build.sh"
if not script.is_file():
    raise FileNotFoundError(f"Build script not found: {script}")

print(f"Running build script: {script}")

try:
    subprocess.run(["bash", str(script)], check=True)
except FileNotFoundError as exc:
    raise RuntimeError("Failed to execute build script: bash not found. Ensure bash is installed and available in PATH.") from exc
except subprocess.CalledProcessError as exc:
    raise RuntimeError(f"Failed to execute build script: build.sh exited with code {exc.returncode}") from exc
