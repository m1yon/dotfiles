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

export interface DiscoveryDeps {
  getRepoInfo: typeof getRepoInfo;
  getBranch: typeof getBranch;
  getWorkflowRuns: typeof getWorkflowRuns;
}

const defaultDeps: DiscoveryDeps = { getRepoInfo, getBranch, getWorkflowRuns };

export async function discoverRuns(
  deps: DiscoveryDeps = defaultDeps,
): Promise<DiscoveryResult> {
  const [{ owner, repo }, branch] = await Promise.all([
    deps.getRepoInfo(),
    deps.getBranch(),
  ]);

  let runs = await deps.getWorkflowRuns(owner, repo, branch);

  while (runs.length === 0) {
    console.log(`Waiting for runs on branch ${branch}...`);
    await Bun.sleep(POLL_INTERVAL_MS);
    runs = await deps.getWorkflowRuns(owner, repo, branch);
  }

  return { runs, branch, owner, repo };
}
