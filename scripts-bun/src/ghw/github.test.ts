import { describe, test, expect, mock, beforeEach, spyOn } from "bun:test";

// Mock Octokit before importing github module
const mockListWorkflowRunsForRepo = mock(() =>
  Promise.resolve({ data: { workflow_runs: [] as any[] } }),
);
const mockGetWorkflowRun = mock(() =>
  Promise.resolve({ data: {} }),
);
const mockListJobsForWorkflowRun = mock(() =>
  Promise.resolve({ data: { jobs: [] as any[] } }),
);

mock.module("octokit", () => ({
  Octokit: class {
    rest = {
      actions: {
        listWorkflowRunsForRepo: mockListWorkflowRunsForRepo,
        getWorkflowRun: mockGetWorkflowRun,
        listJobsForWorkflowRun: mockListJobsForWorkflowRun,
      },
    };
  },
}));

function makeSpawnResult(output: string, exitCode = 0) {
  return {
    stdout: new ReadableStream({
      start(controller: ReadableStreamDefaultController) {
        controller.enqueue(new TextEncoder().encode(output));
        controller.close();
      },
    }),
    stderr: new ReadableStream(),
    exited: Promise.resolve(exitCode),
    pid: 1234,
    kill: () => {},
    stdin: undefined,
  };
}

const spawnSpy = spyOn(Bun, "spawn");

beforeEach(() => {
  spawnSpy.mockReset();
  mockListWorkflowRunsForRepo.mockClear();
  mockGetWorkflowRun.mockClear();
  mockListJobsForWorkflowRun.mockClear();
  spawnSpy.mockReturnValue(makeSpawnResult("") as any);
});

const {
  getAuthToken,
  getRepoInfo,
  getBranch,
  getWorkflowRuns,
  getRun,
  getRunJobs,
} = await import("./github");

describe("getAuthToken", () => {
  test("returns trimmed token on success", async () => {
    spawnSpy.mockReturnValue(makeSpawnResult("ghp_abc123\n") as any);
    const token = await getAuthToken();
    expect(token).toBe("ghp_abc123");
    expect(spawnSpy).toHaveBeenCalledWith(
      ["gh", "auth", "token"],
      expect.objectContaining({ stdout: "pipe" }),
    );
  });

  test("throws on auth failure", async () => {
    spawnSpy.mockReturnValue(makeSpawnResult("", 1) as any);
    await expect(getAuthToken()).rejects.toThrow("Failed to get auth token");
  });
});

describe("getRepoInfo", () => {
  test("returns owner and repo", async () => {
    spawnSpy.mockReturnValue(
      makeSpawnResult(JSON.stringify({ owner: { login: "myorg" }, name: "myrepo" })) as any,
    );
    const info = await getRepoInfo();
    expect(info).toEqual({ owner: "myorg", repo: "myrepo" });
  });

  test("throws on failure", async () => {
    spawnSpy.mockReturnValue(makeSpawnResult("", 1) as any);
    await expect(getRepoInfo()).rejects.toThrow("Failed to get repo info");
  });
});

describe("getBranch", () => {
  test("returns trimmed branch name", async () => {
    spawnSpy.mockReturnValue(makeSpawnResult("feature/my-branch\n") as any);
    const branch = await getBranch();
    expect(branch).toBe("feature/my-branch");
  });

  test("throws on failure", async () => {
    spawnSpy.mockReturnValue(makeSpawnResult("", 1) as any);
    await expect(getBranch()).rejects.toThrow("Failed to get current branch");
  });
});

const sampleRun = {
  id: 123,
  name: "CI",
  run_number: 42,
  status: "in_progress",
  conclusion: null,
  html_url: "https://github.com/o/r/actions/runs/123",
  created_at: "2026-01-01T00:00:00Z",
  updated_at: "2026-01-01T00:01:00Z",
  head_branch: "main",
};

describe("getWorkflowRuns", () => {
  test("returns combined in_progress and queued runs", async () => {
    spawnSpy.mockReturnValue(makeSpawnResult("fake-token") as any);

    const queuedRun = { ...sampleRun, id: 456, status: "queued" };

    mockListWorkflowRunsForRepo
      .mockResolvedValueOnce({ data: { workflow_runs: [sampleRun] } })
      .mockResolvedValueOnce({ data: { workflow_runs: [queuedRun] } });

    const runs = await getWorkflowRuns("owner", "repo", "main");
    expect(runs).toHaveLength(2);
    expect(runs[0]!.id).toBe(123);
    expect(runs[1]!.id).toBe(456);
  });

  test("returns empty array when no runs", async () => {
    spawnSpy.mockReturnValue(makeSpawnResult("fake-token") as any);
    mockListWorkflowRunsForRepo
      .mockResolvedValueOnce({ data: { workflow_runs: [] } })
      .mockResolvedValueOnce({ data: { workflow_runs: [] } });

    const runs = await getWorkflowRuns("owner", "repo", "main");
    expect(runs).toHaveLength(0);
  });

  test("maps fields correctly with defaults for null values", async () => {
    spawnSpy.mockReturnValue(makeSpawnResult("fake-token") as any);
    const runWithNulls = {
      id: 789,
      name: null,
      run_number: 1,
      status: null,
      conclusion: null,
      html_url: "https://example.com",
      created_at: "2026-01-01T00:00:00Z",
      updated_at: "2026-01-01T00:00:00Z",
      head_branch: null,
    };
    mockListWorkflowRunsForRepo
      .mockResolvedValueOnce({ data: { workflow_runs: [runWithNulls] } })
      .mockResolvedValueOnce({ data: { workflow_runs: [] } });

    const runs = await getWorkflowRuns("owner", "repo", "main");
    expect(runs[0]!.name).toBe("Unknown");
    expect(runs[0]!.status).toBe("unknown");
    expect(runs[0]!.head_branch).toBe("main");
  });

  test("throws on API error", async () => {
    spawnSpy.mockReturnValue(makeSpawnResult("fake-token") as any);
    mockListWorkflowRunsForRepo.mockRejectedValueOnce(new Error("API rate limit"));

    await expect(getWorkflowRuns("owner", "repo", "main")).rejects.toThrow("API rate limit");
  });
});

describe("getRun", () => {
  test("returns correctly shaped run", async () => {
    spawnSpy.mockReturnValue(makeSpawnResult("fake-token") as any);
    mockGetWorkflowRun.mockResolvedValueOnce({ data: sampleRun });

    const run = await getRun("owner", "repo", 123);
    expect(run.id).toBe(123);
    expect(run.name).toBe("CI");
    expect(run.conclusion).toBeNull();
  });
});

describe("getRunJobs", () => {
  test("returns correctly shaped jobs", async () => {
    spawnSpy.mockReturnValue(makeSpawnResult("fake-token") as any);
    const sampleJob = {
      id: 1,
      name: "build",
      status: "completed",
      conclusion: "success",
      started_at: "2026-01-01T00:00:00Z",
      completed_at: "2026-01-01T00:01:00Z",
    };
    mockListJobsForWorkflowRun.mockResolvedValueOnce({
      data: { jobs: [sampleJob] },
    });

    const jobs = await getRunJobs("owner", "repo", 123);
    expect(jobs).toHaveLength(1);
    expect(jobs[0]!).toEqual(sampleJob);
  });

  test("handles null fields in jobs", async () => {
    spawnSpy.mockReturnValue(makeSpawnResult("fake-token") as any);
    const jobWithNulls = {
      id: 2,
      name: "test",
      status: "queued",
      conclusion: null,
      started_at: null,
      completed_at: null,
    };
    mockListJobsForWorkflowRun.mockResolvedValueOnce({
      data: { jobs: [jobWithNulls] },
    });

    const jobs = await getRunJobs("owner", "repo", 123);
    expect(jobs[0]!.conclusion).toBeNull();
    expect(jobs[0]!.started_at).toBeNull();
  });
});
