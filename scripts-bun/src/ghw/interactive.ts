import { select } from "@inquirer/prompts";
import type { WorkflowRun } from "./github";

function formatAge(createdAt: string): string {
  const diffMs = Date.now() - new Date(createdAt).getTime();
  const seconds = Math.floor(diffMs / 1000);
  if (seconds < 60) return `${seconds}s ago`;
  const minutes = Math.floor(seconds / 60);
  if (minutes < 60) return `${minutes}m ago`;
  const hours = Math.floor(minutes / 60);
  return `${hours}h ${minutes % 60}m ago`;
}

export async function selectRun(runs: WorkflowRun[]): Promise<WorkflowRun> {
  if (runs.length === 1) return runs[0]!;

  return select({
    message: "Select a workflow run to watch:",
    choices: runs.map((run) => ({
      name: `${run.name} #${run.run_number} (${run.status}) triggered ${formatAge(run.created_at)}`,
      value: run,
    })),
  });
}
