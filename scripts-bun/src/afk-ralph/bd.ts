// Typed wrapper around the `bd` (beads) CLI. Uses `Bun.spawn` and parses
// `--json` output. The main orchestrator never formats a bd argv or parses
// bd JSON directly — it goes through this module.

/**
 * Subset of the fields bd emits on an issue in JSON mode. Only fields used by
 * the orchestrator are typed; unknown fields are preserved via the index
 * signature so callers can opt into them when needed.
 */
export interface BdIssue {
  id: string;
  title: string;
  description?: string;
  design?: string;
  acceptance_criteria?: string;
  status: string;
  priority: number;
  issue_type: string;
  assignee?: string;
  owner?: string;
  created_at?: string;
  updated_at?: string;
  started_at?: string;
  closed_at?: string;
  labels?: string[];
  [key: string]: unknown;
}

export class BdError extends Error {
  constructor(
    message: string,
    public readonly argv: string[],
    public readonly exitCode: number,
    public readonly stderr: string,
  ) {
    super(message);
    this.name = "BdError";
  }
}

async function runBdJson<T>(args: string[]): Promise<T> {
  const argv = ["bd", ...args, "--json", "--no-pager"];
  const proc = Bun.spawn(argv, { stdout: "pipe", stderr: "pipe" });
  const [stdout, stderr, exitCode] = await Promise.all([
    new Response(proc.stdout).text(),
    new Response(proc.stderr).text(),
    proc.exited,
  ]);
  if (exitCode !== 0) {
    throw new BdError(
      `bd ${args.join(" ")} failed (exit ${exitCode}): ${stderr.trim()}`,
      argv,
      exitCode,
      stderr,
    );
  }
  const text = stdout.trim();
  if (!text) {
    // bd emits empty output in some edge cases; treat as empty array/object.
    return [] as unknown as T;
  }
  try {
    return JSON.parse(text) as T;
  } catch (err) {
    throw new BdError(
      `bd ${args.join(" ")} produced non-JSON output: ${(err as Error).message}`,
      argv,
      exitCode,
      stderr,
    );
  }
}

/** List all open epics. Excludes closed. */
export async function listOpenEpics(): Promise<BdIssue[]> {
  return runBdJson<BdIssue[]>([
    "list",
    "--type",
    "epic",
    "--status",
    "open,in_progress",
  ]);
}

/**
 * Show a single issue by id. bd's `show` command emits a JSON array even for
 * a single id; this function unwraps to the first element and throws if
 * the id is not found.
 */
export async function showIssue(id: string): Promise<BdIssue> {
  const result = await runBdJson<BdIssue[] | BdIssue>(["show", id]);
  if (Array.isArray(result)) {
    const first = result[0];
    if (!first) throw new BdError(`bd show ${id} returned no issues`, ["bd", "show", id], 0, "");
    return first;
  }
  return result;
}

/**
 * List AI-labeled ready children of an epic. Uses `bd ready` so the result is
 * blocker-aware (excludes in_progress, blocked, deferred, hooked).
 */
export async function listReadyChildren(
  epicId: string,
  label: string,
): Promise<BdIssue[]> {
  return runBdJson<BdIssue[]>([
    "ready",
    "--parent",
    epicId,
    "--label",
    label,
  ]);
}

/**
 * List children of an epic filtered by label AND status. Used at startup to
 * find stale `in_progress` AI-labeled children left over from a crashed prior
 * run so they can be reset to `open`.
 */
export async function listChildrenByStatus(
  epicId: string,
  label: string,
  status: string,
): Promise<BdIssue[]> {
  return runBdJson<BdIssue[]>([
    "list",
    "--parent",
    epicId,
    "--label",
    label,
    "--status",
    status,
  ]);
}

/**
 * Set an issue's status. Used to reset stale `in_progress` children back to
 * `open` so `bd ready` can pick them up cleanly.
 */
export async function resetStatus(id: string, status: string): Promise<void> {
  const argv = ["bd", "update", id, "--status", status, "--no-pager"];
  const proc = Bun.spawn(argv, { stdout: "pipe", stderr: "pipe" });
  const [, stderr, exitCode] = await Promise.all([
    new Response(proc.stdout).text(),
    new Response(proc.stderr).text(),
    proc.exited,
  ]);
  if (exitCode !== 0) {
    throw new BdError(
      `bd update ${id} --status ${status} failed (exit ${exitCode}): ${stderr.trim()}`,
      argv,
      exitCode,
      stderr,
    );
  }
}
