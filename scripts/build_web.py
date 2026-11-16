"""Build the existing Pages artifact with the tested engine and exact clean commit."""
import argparse
import os
from pathlib import Path
import re
import shutil
import subprocess

from finish_web import finish
from validate_web import validate

ROOT = Path(__file__).resolve().parents[1]
VERSION = (ROOT / "scripts/godot-version.txt").read_text().strip()
GENERATED = (
    "godot/tests/campaign-results.json", "godot/tests/milestone-results.json",
)


def build(godot, output, commit):
    head = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    if not re.fullmatch(r"[0-9a-f]{40}", commit) or head != commit:
        raise ValueError("Build commit must equal the full current Git HEAD SHA")
    source_paths = [".", *(f":(exclude){path}" for path in GENERATED)]
    changed = subprocess.run(["git", "diff", "--quiet", "HEAD", "--", *source_paths], cwd=ROOT)
    untracked = subprocess.check_output(
        ["git", "ls-files", "--others", "--exclude-standard", "--", *source_paths], cwd=ROOT, text=True)
    if changed.returncode != 0 or untracked.strip():
        raise ValueError("Commit reviewed source before building; working tree has source changes")
    output = output.resolve()
    if output == ROOT or output == ROOT / "godot" or (ROOT / "godot") in output.parents:
        raise ValueError("Export output must not overwrite the repository/project source")
    output.mkdir(parents=True, exist_ok=True)
    engine = subprocess.check_output([godot, "--version"], text=True).strip()
    if not engine.startswith(VERSION + ".stable"):
        raise ValueError(f"Expected Godot {VERSION}.stable, received {engine}")
    for arguments in (
        ["--editor", "--import", "--quit"],
        ["--export-release", "Web", str(output / "index.html")],
    ):
        subprocess.run([godot, "--headless", "--path", str(ROOT / "godot"), *arguments], check=True)
    shutil.copy2(ROOT / "classic.html", output / "classic.html")
    for folder in ("src", "styles"):
        shutil.copytree(ROOT / folder, output / folder, dirs_exist_ok=True)
    (output / ".nojekyll").touch()
    finish(output, commit, engine)
    validate(output, commit, VERSION)
    print(f"Validated web artifact: {output}\nSource commit: {commit}\nEngine: {engine}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default=os.environ.get("GODOT_BIN", "godot"))
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--commit", default=os.environ.get("GITHUB_SHA"))
    args = parser.parse_args()
    build(args.godot, args.output, args.commit or subprocess.check_output(
        ["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip())
