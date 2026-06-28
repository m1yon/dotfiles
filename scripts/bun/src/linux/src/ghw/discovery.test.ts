import { describe, test, expect, mock, beforeEach, afterAll, spyOn } from "bun:test";
import { discoverRuns, type DiscoveryDeps } from "./discovery";
import type { WorkflowRun } from "./github";

const sampleRun: WorkflowRun = {
  id: 123,
  name: "CI",
  run_number: 42,
  status: "in_progress",
  conclusion: null,
  html_url: "https://github.com/testorg/testrepo/actions/runs/123",
  created_at: "2026-01-01T00:00:00Z",
  updated_at: "2026-01-01T00:01:00Z",
  head_branch: "main",
};

const mockDeps: DiscoveryDeps = {
  getRepoInfo: mock(() => Promise.resolve({ owner: "testorg", repo: "testrepo" })),
  getBranch: mock(() => Promise.resolve("main")),
  getWorkflowRuns: mock((): Promise<WorkflowRun[]> => Promise.resolve([])),
};

const sleepSpy = spyOn(Bun, "sleep").mockResolvedValue(undefined as any);

afterAll(() => {
  sleepSpy.mockRestore();
});

beforeEach(() => {
  (mockDeps.getRepoInfo as ReturnType<typeof mock>).mockClear();
  (mockDeps.getBranch as ReturnType<typeof mock>).mockClear();
  (mockDeps.getWorkflowRuns as ReturnType<typeof mock>).mockClear();
  sleepSpy.mockClear();
  (mockDeps.getRepoInfo as ReturnType<typeof mock>).mockResolvedValue({
    owner: "testorg",
    repo: "testrepo",
  });
  (mockDeps.getBranch as ReturnType<typeof mock>).mockResolvedValue("main");
});

describe("discoverRuns", () => {
  test("returns immediately when runs exist", async () => {
    (mockDeps.getWorkflowRuns as ReturnType<typeof mock>).mockResolvedValueOnce([sampleRun]);

    const result = await discoverRuns(mockDeps);

    expect(result.runs).toHaveLength(1);
    expect(result.runs[0]!.id).toBe(123);
    expect(result.branch).toBe("main");
    expect(result.owner).toBe("testorg");
    expect(result.repo).toBe("testrepo");
    expect(sleepSpy).not.toHaveBeenCalled();
  });

  test("polls until runs appear", async () => {
    (mockDeps.getWorkflowRuns as ReturnType<typeof mock>)
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([sampleRun]);

    const consoleSpy = spyOn(console, "log").mockImplementation(() => {});

    const result = await discoverRuns(mockDeps);

    expect(result.runs).toHaveLength(1);
    expect(mockDeps.getWorkflowRuns).toHaveBeenCalledTimes(3);
    expect(sleepSpy).toHaveBeenCalledTimes(2);
    expect(consoleSpy).toHaveBeenCalledWith("Waiting for runs on branch main...");

    consoleSpy.mockRestore();
  });

  test("fetches repo info and branch in parallel", async () => {
    (mockDeps.getWorkflowRuns as ReturnType<typeof mock>).mockResolvedValueOnce([sampleRun]);

    await discoverRuns(mockDeps);

    expect(mockDeps.getRepoInfo).toHaveBeenCalledTimes(1);
    expect(mockDeps.getBranch).toHaveBeenCalledTimes(1);
  });

  test("passes correct params to getWorkflowRuns", async () => {
    (mockDeps.getWorkflowRuns as ReturnType<typeof mock>).mockResolvedValueOnce([sampleRun]);

    await discoverRuns(mockDeps);

    expect(mockDeps.getWorkflowRuns).toHaveBeenCalledWith("testorg", "testrepo", "main");
  });

  test("propagates getRepoInfo errors", async () => {
    (mockDeps.getRepoInfo as ReturnType<typeof mock>).mockRejectedValueOnce(
      new Error("Not a repo"),
    );

    await expect(discoverRuns(mockDeps)).rejects.toThrow("Not a repo");
  });

  test("propagates getBranch errors", async () => {
    (mockDeps.getBranch as ReturnType<typeof mock>).mockRejectedValueOnce(
      new Error("No branch"),
    );

    await expect(discoverRuns(mockDeps)).rejects.toThrow("No branch");
  });

  test("propagates getWorkflowRuns API errors", async () => {
    (mockDeps.getWorkflowRuns as ReturnType<typeof mock>).mockRejectedValueOnce(
      new Error("API error"),
    );

    await expect(discoverRuns(mockDeps)).rejects.toThrow("API error");
  });

  test("returns multiple runs when available", async () => {
    const secondRun = { ...sampleRun, id: 456, name: "Deploy" };
    (mockDeps.getWorkflowRuns as ReturnType<typeof mock>).mockResolvedValueOnce([
      sampleRun,
      secondRun,
    ]);

    const result = await discoverRuns(mockDeps);

    expect(result.runs).toHaveLength(2);
    expect(result.runs[0]!.name).toBe("CI");
    expect(result.runs[1]!.name).toBe("Deploy");
  });
});
