"""Fail closed on missing, corrupt, stale or incorrectly identified web artifacts."""
import argparse
import hashlib
import json
from pathlib import Path
import re

FILES = ("index.html", "index.js", "index.wasm", "index.pck", "classic.html")


def fingerprints(output):
    result = {}
    for name in FILES:
        path = output / name
        if not path.is_file() or path.stat().st_size == 0:
            raise ValueError(f"Missing or empty export file: {name}")
        with path.open("rb") as stream:
            digest = hashlib.file_digest(stream, "sha256").hexdigest()
        result[name] = {"bytes":path.stat().st_size, "sha256":digest}
    return result


def validate(output, commit=None, engine=None):
    info = json.loads((output / "build-info.json").read_text(encoding="utf-8"))
    sha = info.get("source_commit", "")
    if not re.fullmatch(r"[0-9a-f]{40}", sha) or (commit and sha != commit):
        raise ValueError("Missing or mismatched release commit")
    if info.get("edition") != "deep-signal-godot" or info.get("threads") is not False:
        raise ValueError("Incorrect edition or threaded export")
    if not info.get("clean_source"):
        raise ValueError("Artifact must come from committed source")
    if engine and not info.get("engine", "").startswith(engine + ".stable"):
        raise ValueError("Mismatched engine version")
    if fingerprints(output) != info.get("files"):
        raise ValueError("Export file size/hash mismatch")
    html = (output / "index.html").read_text(encoding="utf-8")
    if not all(value in html for value in ("index.js", "index.pck", "Engine", sha[:12], "build-info.json")):
        raise ValueError("HTML is not the identified Godot entry point")
    with (output / "index.wasm").open("rb") as stream:
        if stream.read(4) != b"\x00asm": raise ValueError("Invalid WASM header")
    with (output / "index.pck").open("rb") as stream:
        if stream.read(4) != b"GDPC": raise ValueError("Invalid packed game header")
    return info


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", type=Path)
    parser.add_argument("--commit")
    parser.add_argument("--engine")
    args = parser.parse_args()
    result = validate(args.output, args.commit, args.engine)
    print(f"WEB ARTIFACT PASS {result['source_commit']}")
