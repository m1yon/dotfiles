import { select } from "@inquirer/prompts";
import type { WorkflowRun } from "./github";
import { c } from "./display";

function formatAge(createdAt: string): string {
  const diffMs = Date.now() - new Date(createdAt).getTime();
  const seconds = Math.floor(diffMs / 1000);
  if (seconds < 60) return `${seconds}s ago`;
  const minutes = Math.floor(seconds / 60);
  if (minutes < 60) return `${minutes}m ago`;
  const hours = Math.floor(minutes / 60);
  return `${hours}h ${minutes % 60}m ago`;
}

function statusBadge(status: string): string {
  if (status === "in_progress") return c.cyan(status);
  if (status === "queued") return c.yellow(status);
  if (status === "completed") return c.green(status);
  return c.dim_(status);
}

export async function selectRun(runs: WorkflowRun[]): Promise<WorkflowRun> {
  if (runs.length === 1) return runs[0]!;

  return select({
    message: "Select a workflow run to watch:",
    choices: runs.map((run) => ({
      name: `${c.bold_(run.name)} ${c.dim_(`#${run.run_number}`)} (${statusBadge(run.status)}) ${c.dim_(formatAge(run.created_at))}`,
      value: run,
    })),
  });
}
