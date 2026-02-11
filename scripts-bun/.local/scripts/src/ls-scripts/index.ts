#!/usr/bin/env bun
// ---
// description: Lists all scripts from scripts-bash and scripts-bun
// ---
import { readdir, readFile, stat } from "node:fs/promises";
import { join } from "node:path";
import { homedir } from "node:os";

interface ScriptSource {
  /** Directory containing the executables */
  binDir: string;
  /** Label shown in output (e.g. "bash", "bun") */
  label: string;
  /** Whether to skip binary (non-text) files in the bin directory */
  skipBinaries: boolean;
  /** Given a script name, return the path to its source file for front matter parsing */
  resolveSource: (name: string) => string;
}

const SOURCES: ScriptSource[] = [
  {
    binDir: join(homedir(), "dotfiles/scripts-bash/.local/bin"),
    label: "bash",
    skipBinaries: true,
    // bash scripts are their own source
    resolveSource(name) {
      return join(this.binDir, name);
    },
  },
  {
    binDir: join(homedir(), "dotfiles/scripts-bun/.local/scripts/bin"),
    label: "bun",
    skipBinaries: false,
    // bun scripts compile from src/<name>/index.ts
    resolveSource(name) {
      return join(
        homedir(),
        "dotfiles/scripts-bun/.local/scripts/src",
        name,
        "index.ts",
      );
    },
  },
];

interface ScriptEntry {
  name: string;
  label: string;
  description: string | null;
}

/**
 * Parse front matter from the first lines of a file.
 * Expects the format:
 * ```
 * # ---
 * # key: value
 * # ---
 * ```
 * (or `//` comment style for TypeScript)
 */
function parseFrontMatter(content: string): Record<string, string> {
  const lines = content.split("\n");
  const result: Record<string, string> = {};

  let inFrontMatter = false;

  for (const line of lines) {
    const trimmed = line.trim();

    // Match opening delimiter: `# ---` or `// ---`
    if (!inFrontMatter) {
      if (/^(#|\/\/)\s*---\s*$/.test(trimmed)) {
        inFrontMatter = true;
      }
      continue;
    }

    // Match closing delimiter
    if (/^(#|\/\/)\s*---\s*$/.test(trimmed)) {
      break;
    }

    // Match key: value line
    const match = trimmed.match(/^(?:#|\/\/)\s*(\w+):\s*(.+)$/);
    if (match?.[1] && match[2]) {
      result[match[1]] = match[2].trim();
    }
  }

  return result;
}

async function getDescription(sourcePath: string): Promise<string | null> {
  try {
    // Only read the first 512 bytes — front matter should be near the top
    const file = Bun.file(sourcePath);
    const slice = file.slice(0, 512);
    const text = await slice.text();
    const meta = parseFrontMatter(text);
    return meta["description"] ?? null;
  } catch {
    return null;
  }
}

/** Check if a file is binary by looking for null bytes in the first chunk. */
async function isBinaryFile(path: string): Promise<boolean> {
  try {
    const file = Bun.file(path);
    const chunk = new Uint8Array(await file.slice(0, 512).arrayBuffer());
    return chunk.includes(0);
  } catch {
    return false;
  }
}

async function getExecutables(source: ScriptSource): Promise<ScriptEntry[]> {
  let entries: string[];
  try {
    entries = await readdir(source.binDir);
  } catch {
    return [];
  }

  const results: ScriptEntry[] = [];
  for (const entry of entries) {
    const fullPath = join(source.binDir, entry);
    try {
      const s = await stat(fullPath);
      if (s.isFile() && s.mode & 0o111) {
        if (source.skipBinaries && (await isBinaryFile(fullPath))) continue;
        const sourcePath = source.resolveSource(entry);
        const description = await getDescription(sourcePath);
        results.push({ name: entry, label: source.label, description });
      }
    } catch {
      // skip entries we can't stat
    }
  }

  return results;
}

async function main() {
  const allScripts: ScriptEntry[] = [];

  for (const source of SOURCES) {
    const scripts = await getExecutables(source);
    allScripts.push(...scripts);
  }

  allScripts.sort((a, b) => a.name.localeCompare(b.name));

  if (allScripts.length === 0) {
    console.log("No scripts found.");
    return;
  }

  const maxName = Math.max(...allScripts.map((s) => s.name.length));
  const maxLabel = Math.max(...allScripts.map((s) => s.label.length));

  const useColor = process.stdout.isTTY ?? false;

  const c = {
    reset: useColor ? "\x1b[0m" : "",
    bold: useColor ? "\x1b[1m" : "",
    cyan: useColor ? "\x1b[36m" : "",
    yellow: useColor ? "\x1b[33m" : "",
    green: useColor ? "\x1b[32m" : "",
    dim: useColor ? "\x1b[2m" : "",
  };

  const labelColors: Record<string, string> = {
    bash: useColor ? "\x1b[33m" : "", // yellow
    bun: useColor ? "\x1b[35m" : "", // magenta
  };

  for (const script of allScripts) {
    const nameCol = `${c.bold}${c.cyan}${script.name.padEnd(maxName)}${c.reset}`;
    const labelColor = labelColors[script.label] ?? c.dim;
    const labelCol = `${labelColor}(${script.label})${c.reset}`.padEnd(
      maxLabel + 2 + (labelColor.length + c.reset.length),
    );
    const descCol = script.description
      ? `${c.dim}${script.description}${c.reset}`
      : "";
    console.log(`${nameCol}  ${labelCol}  ${descCol}`);
  }
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
