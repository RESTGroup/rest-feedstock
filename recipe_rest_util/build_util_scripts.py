import glob
import os
import pathlib
import shutil


prefix = pathlib.Path(os.environ["PREFIX"])
target = os.environ.get("TARGET_PLATFORM") or os.environ.get("target_platform")
if not target:
    raise RuntimeError("TARGET_PLATFORM (or target_platform) is required")

destination = prefix / ("Scripts" if target.startswith("win-") else "bin")
destination.mkdir(parents=True, exist_ok=True)

utilities_dir = pathlib.Path.cwd() / "utilities"
sources = sorted(utilities_dir.glob("*.py"))
if not sources:
    raise FileNotFoundError(f"No utility scripts found in {utilities_dir}")

for source in sources:
    shutil.copy2(source, destination / source.name)
