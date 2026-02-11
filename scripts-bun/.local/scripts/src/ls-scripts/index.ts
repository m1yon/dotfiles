#!/usr/bin/env bun
import { readdir, stat } from "node:fs/promises";
import { join } from "node:path";
import { homedir } from "node:os";

const SCRIPT_DIRS: { path: string; label: string }[] = [
  { path: join(homedir(), "dotfiles/scripts-bash/.local/bin"), label: "bash" },
  {
    path: join(homedir(), "dotfiles/scripts-bun/.local/scripts/bin"),
    label: "bun",
  },
];

interface ScriptEntry {
  name: string;
  source: string;
}

async function getExecutables(
  dir: string,
  label: string,
): Promise<ScriptEntry[]> {
  const source = label;

  let entries: string[];
  try {
    entries = await readdir(dir);
  } catch {
    return [];
  }

  const results: ScriptEntry[] = [];
  for (const entry of entries) {
    const fullPath = join(dir, entry);
    try {
      const s = await stat(fullPath);
      // Check if it's a file (or symlink target) and is executable
      if (s.isFile() && s.mode & 0o111) {
        results.push({ name: entry, source });
      }
    } catch {
      // skip entries we can't stat
    }
  }

  return results;
}

async function main() {
  const allScripts: ScriptEntry[] = [];

  for (const { path, label } of SCRIPT_DIRS) {
    const scripts = await getExecutables(path, label);
    allScripts.push(...scripts);
  }

  allScripts.sort((a, b) => a.name.localeCompare(b.name));

  if (allScripts.length === 0) {
    console.log("No scripts found.");
    return;
  }

  const maxName = Math.max(...allScripts.map((s) => s.name.length));

  for (const script of allScripts) {
    console.log(`${script.name.padEnd(maxName)}  (${script.source})`);
  }
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
