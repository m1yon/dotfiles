import {
  getBranch,
  getRepoInfo,
  getWorkflowRuns,
  type WorkflowRun,
} from "./github";

const POLL_INTERVAL_MS = 10_000;

export interface DiscoveryResult {
  runs: WorkflowRun[];
  branch: string;
  owner: string;
  repo: string;
}

export async function discoverRuns(): Promise<DiscoveryResult> {
  const [{ owner, repo }, branch] = await Promise.all([
    getRepoInfo(),
    getBranch(),
  ]);

  let runs = await getWorkflowRuns(owner, repo, branch);

  while (runs.length === 0) {
    console.log(`Waiting for runs on branch ${branch}...`);
    await Bun.sleep(POLL_INTERVAL_MS);
    runs = await getWorkflowRuns(owner, repo, branch);
  }

  return { runs, branch, owner, repo };
}
