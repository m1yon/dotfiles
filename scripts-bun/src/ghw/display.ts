import type { Job, WorkflowRun } from "./github";
import { getRunJobs, getRun } from "./github";

const POLL_INTERVAL_MS = 10_000;

// ANSI color helpers
export const c = {
  reset: "\x1b[0m",
  bold: "\x1b[1m",
  dim: "\x1b[2m",
  underline: "\x1b[4m",
  green: (s: string) => `\x1b[32m${s}\x1b[0m`,
  red: (s: string) => `\x1b[31m${s}\x1b[0m`,
  yellow: (s: string) => `\x1b[33m${s}\x1b[0m`,
  cyan: (s: string) => `\x1b[36m${s}\x1b[0m`,
  dim_: (s: string) => `\x1b[2m${s}\x1b[0m`,
  bold_: (s: string) => `\x1b[1m${s}\x1b[0m`,
  greenBold: (s: string) => `\x1b[1;32m${s}\x1b[0m`,
  redBold: (s: string) => `\x1b[1;31m${s}\x1b[0m`,
  yellowBold: (s: string) => `\x1b[1;33m${s}\x1b[0m`,
  link: (s: string) => `\x1b[2;4m${s}\x1b[0m`,
};

const INDICATORS: Record<string, string> = {
  completed_success: c.green("\u2713"),
  completed_failure: c.red("\u2717"),
  completed_cancelled: c.yellow("!"),
  in_progress: c.cyan("\u25CF"),
  queued: c.dim_("\u25CB"),
};

export function formatDuration(startedAt: string, endedAt: string): string {
  const ms = new Date(endedAt).getTime() - new Date(startedAt).getTime();
  const totalSeconds = Math.floor(ms / 1000);
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = totalSeconds % 60;
  if (minutes === 0) return `${seconds}s`;
  return `${minutes}m ${seconds}s`;
}

function getIndicator(job: Job): string {
  if (job.status === "completed") {
    return INDICATORS[`completed_${job.conclusion}`] ?? c.dim_("?");
  }
  return INDICATORS[job.status] ?? c.dim_("?");
}

function statusColor(status: string): (s: string) => string {
  if (status === "completed") return c.green;
  if (status === "in_progress") return c.cyan;
  return c.dim_;
}

function renderJobs(run: WorkflowRun, jobs: Job[]): string {
  const colorize = statusColor(run.status);
  const lines = [
    `${c.bold_(run.name)} ${c.dim_(`#${run.run_number}`)} ${colorize(run.status)}`,
  ];
  for (const job of jobs) {
    lines.push(`  ${getIndicator(job)} ${job.name}`);
  }
  return lines.join("\n");
}

export interface WatchResult {
  run: WorkflowRun;
  jobs: Job[];
}

export async function watchRun(
  owner: string,
  repo: string,
  run: WorkflowRun,
): Promise<WatchResult> {
  let previousLineCount = 0;

  while (true) {
    const jobs = await getRunJobs(owner, repo, run.id);

    // Refresh run status
    const updatedRun = await getRun(owner, repo, run.id);

    // Clear previous output
    if (previousLineCount > 0) {
      process.stdout.write(`\x1b[${previousLineCount}A\x1b[J`);
    }

    const currentRun = updatedRun;
    const output = renderJobs(currentRun, jobs);
    process.stdout.write(output + "\n");
    previousLineCount = output.split("\n").length;

    // Check for terminal state
    if (
      currentRun.status === "completed" ||
      currentRun.conclusion === "failure" ||
      currentRun.conclusion === "cancelled"
    ) {
      return { run: currentRun, jobs };
    }

    await Bun.sleep(POLL_INTERVAL_MS);
  }
}

export function printSummary({ run, jobs }: WatchResult): void {
  const conclusion = run.conclusion ?? "unknown";
  const indicator = INDICATORS[`completed_${conclusion}`] ?? c.dim_("?");
  const duration = formatDuration(run.created_at, run.updated_at);

  const conclusionLabel =
    conclusion === "success"
      ? c.greenBold("completed")
      : conclusion === "failure"
        ? c.redBold("failed")
        : conclusion === "cancelled"
          ? c.yellowBold("cancelled")
          : c.dim_(conclusion);

  console.log(
    `\n${indicator} ${c.bold_(run.name)} ${conclusionLabel} in ${c.bold_(duration)}`,
  );
  for (const job of jobs) {
    console.log(`  ${getIndicator(job)} ${job.name}`);
  }
  console.log(`\n${c.link(run.html_url)}`);
}
