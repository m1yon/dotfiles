#!/usr/bin/env python3
import argparse
import hashlib
import json
from pathlib import Path
import stat
import zipfile


source = Path(__file__).resolve().with_name("start-skill.md")
parser = argparse.ArgumentParser(description="Package the shared Cloud startup loader.")
parser.add_argument(
    "output_directory", nargs="?", type=Path,
    default=source.parents[3] / ".audit/cloud-loader-plugin",
)
arguments = parser.parse_args()
skill = source.read_bytes()
text = skill.decode("utf-8")
if not text.startswith("---\n") or "\n---\n" not in text[4:]:
    raise SystemExit("Skill frontmatter is missing")
frontmatter, body = text[4:].split("\n---\n", 1)
metadata = dict(line.split(": ", 1) for line in frontmatter.splitlines())
if set(metadata) != {"name", "description"} or metadata["name"] != "shared-agent-bootstrap":
    raise SystemExit("Unexpected skill metadata")
if not 1 <= len(metadata["description"]) <= 1024 or not body.strip():
    raise SystemExit("Skill description or body is empty or too long")
if any(character in metadata["description"] for character in "\n:#{}[]&*!|>'\"%@`"):
    raise SystemExit("Description requires YAML quoting")

manifest = {
    "$schema": "https://agent-plugins.org/schemas/1.0.0/plugin.schema.json",
    "name": "cloud-agent-bootstrap",
    "version": "0.1.1",
    "description": metadata["description"],
}
files = {
    "plugin.json": (json.dumps(manifest, indent=2) + "\n").encode("utf-8"),
    "skills/shared-agent-bootstrap/SKILL.md": skill,
}
arguments.output_directory.mkdir(parents=True, exist_ok=True)
archive = arguments.output_directory / f"{manifest['name']}-{manifest['version']}.zip"
with zipfile.ZipFile(archive, "w") as output:
    for name, content in files.items():
        entry = zipfile.ZipInfo(name, date_time=(1980, 1, 1, 0, 0, 0))
        entry.create_system = 3
        entry.external_attr = (stat.S_IFREG | 0o644) << 16
        output.writestr(entry, content)

with zipfile.ZipFile(archive) as result:
    if result.namelist() != list(files) or result.testzip() is not None:
        raise SystemExit("Archive contents or CRC validation failed")
    for name, content in files.items():
        if result.read(name) != content:
            raise SystemExit(f"Archive content differs: {name}")

print(f"Archive: {archive.resolve()}")
print(f"SHA256: {hashlib.sha256(archive.read_bytes()).hexdigest()}")
