// On-disk progress document for an afk-ralph epic run. Pure file and string
// manipulation — no bd, git, or GitHub calls. One file per epic, committed by
// the sub-agent alongside its code so cross-iteration context persists in
// git history.
//
// File layout (matches the prior Linear document shape):
//
//     # Progress — <epic-id>: <epic-title>
//
//     Running log for afk-ralph iterations. ...
//
//     ---
//
//     ## <bd-id>: <issue title>
//
//     _<timestamp> · <status>_
//
//     <agent body>
//
// The `---` separator divides the intro from the first entry. Everything
// after the first `---` is the accumulated entries.
//
// Paths are resolved relative to `process.cwd()` (the repo root — see
// prompt-implement-issue.md for the corresponding assumption on the
// sub-agent side).

import { mkdir } from "node:fs/promises";
import { dirname } from "node:path";

const DIR = ".afk-ralph";
const SEPARATOR = "---";

/** Absolute-ish path (relative to cwd) of the progress doc for an epic. */
export function filepath(epicId: string): string {
  return `${DIR}/progress-${epicId}.md`;
}

function initialContent(epicId: string, epicTitle: string): string {
  return (
    `# Progress — ${epicId}: ${epicTitle}\n` +
    `\n` +
    `Running log for afk-ralph iterations. Each sub-issue agent appends one entry. Concise — this is context for the next agent, not documentation.\n` +
    `\n` +
    `${SEPARATOR}\n`
  );
}

/**
 * Ensure the progress file exists. If it's missing, create it (and its parent
 * directory) with the initial header. No-op if the file is already present —
 * never overwrites existing content.
 */
export async function ensure(epicId: string, epicTitle: string): Promise<void> {
  const path = filepath(epicId);
  const file = Bun.file(path);
  if (await file.exists()) return;
  await mkdir(dirname(path), { recursive: true });
  await Bun.write(path, initialContent(epicId, epicTitle));
}

/**
 * Read the progress file for an epic. Returns "" if the file does not exist
 * (callers should typically call `ensure` first, but this is permissive to
 * keep the call-site simple).
 */
export async function read(epicId: string): Promise<string> {
  const file = Bun.file(filepath(epicId));
  if (!(await file.exists())) return "";
  return file.text();
}

/**
 * Extract the accumulated entries (everything after the first `---`
 * separator) and wrap them in a labelled section suitable for injection into
 * a sub-agent's prompt. Returns "" when there are no entries yet so the
 * prompt template collapses cleanly.
 */
export function buildProgressSection(content: string): string {
  if (!content) return "";
  const idx = content.indexOf(`\n${SEPARATOR}`);
  if (idx === -1) return "";
  // Skip past the separator line itself.
  const afterSeparator = content.slice(idx + 1 + SEPARATOR.length);
  const entries = afterSeparator.trim();
  if (!entries) return "";
  return `\n# Prior Progress\n\n${entries}\n`;
}

/**
 * Format a single progress entry: `## <id>: <title>` heading, a timestamped
 * italic subhead with the status, then the sub-agent's body verbatim. Used
 * by the sub-agent (indirectly — the sub-agent writes its block to the file
 * directly) and by any orchestrator-side fallback tooling.
 */
export function formatEntry(
  issue: { id: string; title: string },
  status: "completed" | "blocked",
  body: string,
): string {
  const ts = new Date().toISOString().replace(/\.\d+Z$/, "Z");
  return `## ${issue.id}: ${issue.title}\n\n_${ts} · ${status}_\n\n${body.trim()}`;
}
