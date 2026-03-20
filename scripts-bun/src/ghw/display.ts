import type { Job, WorkflowRun } from "./github";
import { getRunJobs, getRun } from "./github";

const POLL_INTERVAL_MS = 10_000;

const INDICATORS: Record<string, string> = {
  completed_success: "\u2713",
  completed_failure: "\u2717",
  completed_cancelled: "!",
  in_progress: "\u25CF",
  queued: "\u25CB",
};

function getIndicator(job: Job): string {
  if (job.status === "completed") {
    return INDICATORS[`completed_${job.conclusion}`] ?? "?";
  }
  return INDICATORS[job.status] ?? "?";
}

function renderJobs(run: WorkflowRun, jobs: Job[]): string {
  const lines = [`${run.name} #${run.run_number} (${run.status})`];
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
