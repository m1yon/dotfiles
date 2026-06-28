import { Octokit } from "octokit";

export interface RepoInfo {
  owner: string;
  repo: string;
}

export interface WorkflowRun {
  id: number;
  name: string;
  run_number: number;
  status: string;
  conclusion: string | null;
  html_url: string;
  created_at: string;
  updated_at: string;
  head_branch: string;
}

export interface Job {
  id: number;
  name: string;
  status: string;
  conclusion: string | null;
  started_at: string | null;
  completed_at: string | null;
}

async function runCommand(
  args: string[],
  errorMessage: string,
): Promise<string> {
  const proc = Bun.spawn(args, {
    stdout: "pipe",
    stderr: "pipe",
  });
  const output = await new Response(proc.stdout).text();
  const exitCode = await proc.exited;

  if (exitCode !== 0) {
    throw new Error(errorMessage);
  }

  return output.trim();
}

export async function getAuthToken(): Promise<string> {
  return runCommand(
    ["gh", "auth", "token"],
    "Failed to get auth token. Are you logged in with `gh auth login`?",
  );
}

export async function getRepoInfo(): Promise<RepoInfo> {
  const output = await runCommand(
    ["gh", "repo", "view", "--json", "owner,name"],
    "Failed to get repo info. Are you in a GitHub repository?",
  );
  const data = JSON.parse(output);
  return { owner: data.owner.login, repo: data.name };
}

export async function getBranch(): Promise<string> {
  return runCommand(
    ["git", "rev-parse", "--abbrev-ref", "HEAD"],
    "Failed to get current branch. Are you in a git repository?",
  );
}

export async function getWorkflowRuns(
  owner: string,
  repo: string,
  branch: string,
): Promise<WorkflowRun[]> {
  const token = await getAuthToken();
  const octokit = new Octokit({ auth: token });

  const response = await octokit.rest.actions.listWorkflowRunsForRepo({
    owner,
    repo,
    branch,
    status: "in_progress" as const,
    per_page: 100,
  });

  const inProgress = response.data.workflow_runs;

  const queuedResponse = await octokit.rest.actions.listWorkflowRunsForRepo({
    owner,
    repo,
    branch,
    status: "queued" as const,
    per_page: 100,
  });

  const queued = queuedResponse.data.workflow_runs;

  const allRuns = [...inProgress, ...queued];

  return allRuns.map((run) => ({
    id: run.id,
    name: run.name ?? "Unknown",
    run_number: run.run_number,
    status: run.status ?? "unknown",
    conclusion: run.conclusion ?? null,
    html_url: run.html_url,
    created_at: run.created_at,
    updated_at: run.updated_at,
    head_branch: run.head_branch ?? branch,
  }));
}

export async function getRun(
  owner: string,
  repo: string,
  runId: number,
): Promise<WorkflowRun> {
  const token = await getAuthToken();
  const octokit = new Octokit({ auth: token });

  const response = await octokit.rest.actions.getWorkflowRun({
    owner,
    repo,
    run_id: runId,
  });

  const run = response.data;
  return {
    id: run.id,
    name: run.name ?? "Unknown",
    run_number: run.run_number,
    status: run.status ?? "unknown",
    conclusion: run.conclusion ?? null,
    html_url: run.html_url,
    created_at: run.created_at,
    updated_at: run.updated_at,
    head_branch: run.head_branch ?? "",
  };
}

export async function getRunJobs(
  owner: string,
  repo: string,
  runId: number,
): Promise<Job[]> {
  const token = await getAuthToken();
  const octokit = new Octokit({ auth: token });

  const response = await octokit.rest.actions.listJobsForWorkflowRun({
    owner,
    repo,
    run_id: runId,
  });

  return response.data.jobs.map((job) => ({
    id: job.id,
    name: job.name,
    status: job.status,
    conclusion: job.conclusion ?? null,
    started_at: job.started_at ?? null,
    completed_at: job.completed_at ?? null,
  }));
}
