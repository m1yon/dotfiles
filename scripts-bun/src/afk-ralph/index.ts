#! /usr/bin/env bun
// ---
// description: Run Claude in a loop to complete beads epic AI-labeled children automatically
// ---
import {
  select,
  confirm,
  spinner,
  isCancel,
  cancel,
  log,
} from "@clack/prompts";
import { query } from "@anthropic-ai/claude-agent-sdk";
import { logQueryMessage } from "./log-query-message";
import { renderPrompt } from "./render-prompt";
import { Octokit } from "octokit";
import {
  listOpenEpics,
  listReadyChildren,
  listChildrenByStatus,
  resetStatus,
  addLabel,
  doltPush,
  showIssue,
  type BdIssue,
} from "./bd";
import * as progressDoc from "./progress-doc";
import promptImplementIssue from "./prompt-implement-issue.md" with { type: "text" };
import promptInvestigateIssue from "./prompt-investigate-issue.md" with { type: "text" };
import promptPrBody from "./prompt-pr-body.md" with { type: "text" };

type EffortLevel = "low" | "medium" | "high" | "max";
type Mode = "code" | "investigate";
type RunMode = "single" | "afk";

function ensure<T>(value: T | symbol): T {
  if (isCancel(value)) {
    cancel("Operation cancelled.");
    process.exit(0);
  }
  return value as T;
}

async function promptModelAndEffort(): Promise<{ model: string; effort: EffortLevel }> {
  const model = ensure(
    await select({
      message: "Select a model:",
      options: [
        { value: "opus", label: "Opus", hint: "most capable" },
        { value: "sonnet", label: "Sonnet", hint: "balanced" },
        { value: "haiku", label: "Haiku", hint: "fastest" },
      ],
      initialValue: "sonnet",
    }),
  );

  const effort = ensure(
    await select({
      message: "Select a thinking level:",
      options: [
        { value: "low", label: "Low", hint: "minimal thinking, fastest" },
        { value: "medium", label: "Medium", hint: "moderate thinking" },
        { value: "high", label: "High", hint: "deep reasoning (default)" },
        { value: "max", label: "Max", hint: "Opus 4.6 only" },
      ],
      initialValue: "high",
    }),
  );

  return { model: model as string, effort: effort as EffortLevel };
}

async function promptMode(): Promise<Mode> {
  const mode = ensure(
    await select({
      message: "Select a mode:",
      options: [
        { value: "code", label: "Code", hint: "implement, commit, push, open PR" },
        { value: "investigate", label: "Investigate", hint: "no code changes or commits" },
      ],
      initialValue: "code",
    }),
  );
  return mode as Mode;
}

async function promptRunMode(): Promise<RunMode> {
  const runMode = ensure(
    await select({
      message: "Run mode:",
      options: [
        { value: "single", label: "Single", hint: "run one sub-issue then stop" },
        { value: "afk", label: "AFK", hint: "run until all sub-issues complete" },
      ],
      initialValue: "afk",
    }),
  );
  return runMode as RunMode;
}

const PROMPTS: Record<string, string> = {
  "prompt-implement-issue.md": promptImplementIssue,
  "prompt-investigate-issue.md": promptInvestigateIssue,
  "prompt-pr-body.md": promptPrBody,
};

function loadPrompt(filename: string, vars: Record<string, string>): string {
  const template = PROMPTS[filename];
  if (!template) throw new Error(`Unknown prompt: ${filename}`);
  return renderPrompt(template, vars);
}

const CLAUDE_PATH = Bun.spawnSync(["which", "claude"]).stdout.toString().trim();
if (!CLAUDE_PATH) {
  console.error("ERROR: claude not found on PATH");
  process.exit(1);
}

// --- Branch naming ---

/**
 * Slugify a title for use in a git branch name.
 *
 * Rules: lowercase; any character outside [a-z0-9] becomes `-`; runs of `-`
 * collapsed; leading/trailing `-` trimmed; total length capped near 40 chars.
 */
export function slugifyTitle(title: string): string {
  const lowered = title.toLowerCase();
  // Replace any non-[a-z0-9] with `-`. This covers unicode, emoji, whitespace, punctuation.
  const replaced = lowered.replace(/[^a-z0-9]+/g, "-");
  const collapsed = replaced.replace(/-+/g, "-");
  const trimmed = collapsed.replace(/^-+|-+$/g, "");
  const MAX = 40;
  if (trimmed.length <= MAX) return trimmed;
  // Cap near 40 chars and re-trim trailing `-` so we don't end on a dash.
  return trimmed.slice(0, MAX).replace(/-+$/g, "");
}

function branchNameForEpic(epic: { id: string; title: string }): string {
  const slug = slugifyTitle(epic.title);
  return slug ? `${epic.id}/${slug}` : epic.id;
}

// --- GitHub Module ---

async function getAuthToken(): Promise<string> {
  const proc = Bun.spawn(["gh", "auth", "token"], {
    stdout: "pipe",
    stderr: "pipe",
  });
  const output = await new Response(proc.stdout).text();
  if ((await proc.exited) !== 0) {
    throw new Error(
      "Failed to get auth token. Are you logged in with `gh auth login`?",
    );
  }
  return output.trim();
}

async function getRepoInfo(): Promise<{ owner: string; repo: string }> {
  const proc = Bun.spawn(["gh", "repo", "view", "--json", "owner,name"], {
    stdout: "pipe",
    stderr: "pipe",
  });
  const output = await new Response(proc.stdout).text();
  if ((await proc.exited) !== 0) {
    throw new Error("Failed to get repo info. Are you in a GitHub repository?");
  }
  const data = JSON.parse(output);
  return { owner: data.owner.login, repo: data.name };
}

async function getCurrentBranch(): Promise<string> {
  const proc = Bun.spawn(["git", "rev-parse", "--abbrev-ref", "HEAD"], {
    stdout: "pipe",
    stderr: "pipe",
  });
  const output = await new Response(proc.stdout).text();
  if ((await proc.exited) !== 0) {
    throw new Error("Failed to get current branch.");
  }
  return output.trim();
}

async function generatePrBody(
  epic: { identifier: string; title: string; description: string },
  baseBranch: string,
  model: string,
  effort: EffortLevel,
): Promise<string> {
  const prompt = loadPrompt("prompt-pr-body.md", {
    baseBranch,
    prdIdentifier: epic.identifier,
    prdTitle: epic.title,
    prdDescription: epic.description || "(none)",
  });

  let resultText = "";
  for await (const message of query({
    prompt,
    options: {
      cwd: process.cwd(),
      model,
      effort,
      allowedTools: ["Bash", "Read", "Glob", "Grep"],
      permissionMode: "bypassPermissions",
      allowDangerouslySkipPermissions: true,
      maxTurns: 10,
      settingSources: ["project"],
      pathToClaudeCodeExecutable: CLAUDE_PATH,
      stderr: (data: string) => console.log(data),
    },
  })) {
    logQueryMessage(message);
    if (message.type === "result" && message.subtype === "success") {
      resultText = (message as any).result ?? "";
    }
  }

  return (
    resultText ||
    `## ${epic.identifier}: ${epic.title}\n\n${epic.description ?? ""}`
  );
}

async function createOrUpdatePullRequest(
  epic: { identifier: string; title: string; description: string },
  branchName: string,
  baseBranch: string,
  model: string,
  effort: EffortLevel,
): Promise<string> {
  const authToken = await getAuthToken();
  const octokit = new Octokit({ auth: authToken });
  const { owner, repo } = await getRepoInfo();

  const title = `${epic.identifier}: ${epic.title}`;

  // Check for existing PR on this branch
  const { data: existing } = await octokit.rest.pulls.list({
    owner,
    repo,
    head: `${owner}:${branchName}`,
    state: "open",
  });

  if (existing.length > 0) {
    const pr = existing[0]!;
    const shouldUpdate = ensure(
      await confirm({
        message: `PR #${pr.number} already exists. Update its description?`,
      }),
    );

    if (shouldUpdate) {
      const body = await generatePrBody(epic, baseBranch, model, effort);
      await octokit.rest.pulls.update({
        owner,
        repo,
        pull_number: pr.number,
        title,
        body,
      });
    }
    return pr.html_url;
  }

  const body = await generatePrBody(epic, baseBranch, model, effort);
  const response = await octokit.rest.pulls.create({
    owner,
    repo,
    title,
    head: branchName,
    base: baseBranch,
    body,
  });

  return response.data.html_url;
}

// --- Git Module ---

async function checkoutBranch(branchName: string): Promise<void> {
  // Try to check out existing branch first, otherwise create it
  const checkout = Bun.spawn(["git", "checkout", branchName], {
    stdout: "pipe",
    stderr: "pipe",
  });
  if ((await checkout.exited) === 0) return;

  const create = Bun.spawn(["git", "checkout", "-b", branchName], {
    stdout: "pipe",
    stderr: "pipe",
  });
  if ((await create.exited) !== 0) {
    const stderr = await new Response(create.stderr).text();
    throw new Error(`Failed to create branch ${branchName}: ${stderr.trim()}`);
  }
}

// --- Claude Orchestration ---

async function runClaude(
  epicTitle: string,
  epicDescription: string,
  progressSection: string,
  issue: {
    identifier: string;
    title: string;
    description: string;
    comments: string[];
  },
  model: string,
  effort: EffortLevel,
  mode: Mode,
): Promise<{ success: boolean; error?: string; resultText?: string }> {
  const commentsSection =
    issue.comments.length > 0
      ? `## Comments\n\n${issue.comments.join("\n\n")}`
      : "";

  const promptFile =
    mode === "investigate"
      ? "prompt-investigate-issue.md"
      : "prompt-implement-issue.md";
  const prompt = loadPrompt(promptFile, {
    prdTitle: epicTitle,
    prdDescription: epicDescription,
    progressSection,
    issueIdentifier: issue.identifier,
    issueTitle: issue.title,
    issueDescription: issue.description || "(no description)",
    issueComments: commentsSection,
  });

  try {
    for await (const message of query({
      prompt,
      options: {
        cwd: process.cwd(),
        model,
        effort,
        allowedTools: ["Read", "Edit", "Write", "Bash", "Glob", "Grep", "Skill"],
        permissionMode: "bypassPermissions",
        allowDangerouslySkipPermissions: true,
        maxTurns: 500,
        settingSources: ["user", "project"],
        pathToClaudeCodeExecutable: CLAUDE_PATH,
        stderr: (data: string) => console.log(data),
      },
    })) {
      logQueryMessage(message);
      if (message.type === "result") {
        if (message.subtype === "success") {
          const resultText = ((message as any).result ?? "") as string;
          return { success: true, resultText };
        } else {
          const errors =
            "errors" in message ? (message.errors as string[]) : [];
          return {
            success: false,
            error: `${message.subtype}: ${errors.join(", ")}`,
          };
        }
      }
    }
    return { success: false, error: "No result message received" };
  } catch (err) {
    return {
      success: false,
      error: `Claude process crashed: ${err}`,
    };
  }
}

function parseAgentStatus(resultText: string): "completed" | "blocked" | "missing" {
  const match = resultText.match(/\*\*Status:\*\*\s*(completed|blocked)/i);
  if (!match) return "missing";
  return match[1]!.toLowerCase() as "completed" | "blocked";
}

/**
 * Verify the sub-agent's self-reported `**Status:**` marker against the
 * authoritative bd status for the issue. Logs a non-fatal warning on mismatch
 * so the main loop can continue. bd remains the source of truth for routing.
 *
 * Mapping: marker `completed` ↔ bd `closed`; marker `blocked` ↔ bd `blocked`.
 */
async function verifyAgentStatusAgainstBd(
  issueId: string,
  issueTitle: string,
  agentStatus: "completed" | "blocked",
): Promise<void> {
  let bdIssue: BdIssue;
  try {
    bdIssue = await showIssue(issueId);
  } catch (err: any) {
    console.error(
      yellow(
        `  ! ${issueId} status verification failed: could not read bd status (${err?.message ?? err}).`,
      ),
    );
    return;
  }
  const bdStatus = bdIssue.status;
  const expectedBdStatus = agentStatus === "completed" ? "closed" : "blocked";
  if (bdStatus === expectedBdStatus) return;
  console.error(
    yellow(
      `  ! ${issueId} (${issueTitle}) status mismatch: sub-agent reported **Status:** ${agentStatus} but bd status is ${bdStatus}. Sub-agent may not have ${agentStatus === "completed" ? "closed" : "blocked"} the issue — investigate with \`bd show ${issueId}\`.`,
    ),
  );
}

// --- Feedback Resolution ---
// TODO(dotfiles-99s.7): wire Feedback-label PR-thread resolution back in. The
// helpers below are kept (they don't touch Linear) so the machinery is ready
// to reuse; they're currently unreferenced by the main loop.

interface FeedbackMetadata {
  threadId: string | null;
  commentId: number;
  commentType: "review" | "issue";
  prNumber: number;
}

// eslint-disable-next-line @typescript-eslint/no-unused-vars
function parseFeedbackMetadata(description: string): FeedbackMetadata[] {
  const results: FeedbackMetadata[] = [];
  const regex =
    /<!-- afk-ralph-metadata\s+threadId:\s*(.+)\s+commentId:\s*(\d+)\s+commentType:\s*(\w+)\s+prNumber:\s*(\d+)\s*-->/g;
  let match;
  while ((match = regex.exec(description)) !== null) {
    results.push({
      threadId: match[1]!.trim() === "null" ? null : match[1]!.trim(),
      commentId: parseInt(match[2]!, 10),
      commentType: match[3]!.trim() as "review" | "issue",
      prNumber: parseInt(match[4]!, 10),
    });
  }
  return results;
}

// eslint-disable-next-line @typescript-eslint/no-unused-vars
async function getShortCommitSha(): Promise<string> {
  const proc = Bun.spawn(["git", "log", "-1", "--format=%h"], {
    stdout: "pipe",
    stderr: "pipe",
  });
  await proc.exited;
  return (await new Response(proc.stdout).text()).trim();
}

// eslint-disable-next-line @typescript-eslint/no-unused-vars
async function resolveFeedbackOnGitHub(
  metadata: FeedbackMetadata[],
  commitSha: string,
): Promise<void> {
  const authToken = await getAuthToken();
  const octokit = new Octokit({ auth: authToken });
  const { owner, repo } = await getRepoInfo();
  const body = `Addressed in ${commitSha}.`;

  for (const item of metadata) {
    // Reply to the comment
    if (item.commentType === "review") {
      await octokit.rest.pulls.createReplyForReviewComment({
        owner,
        repo,
        pull_number: item.prNumber,
        comment_id: item.commentId,
        body,
      });
    } else {
      await octokit.rest.issues.createComment({
        owner,
        repo,
        issue_number: item.prNumber,
        body,
      });
    }

    // Resolve the thread if it's a review comment
    if (item.commentType === "review" && item.threadId) {
      await octokit.graphql(
        `mutation($threadId: ID!) {
          resolveReviewThread(input: { threadId: $threadId }) {
            thread { isResolved }
          }
        }`,
        { threadId: item.threadId },
      );
    }
  }
}

// --- Main ---

// ANSI helpers
const dim = (s: string) => `\x1b[90m${s}\x1b[0m`;
const bold = (s: string) => `\x1b[1m${s}\x1b[0m`;
const orange = (s: string) => `\x1b[38;2;227;137;58m${s}\x1b[0m`;
const green = (s: string) => `\x1b[32m${s}\x1b[0m`;
const cyan = (s: string) => `\x1b[36m${s}\x1b[0m`;
const yellow = (s: string) => `\x1b[33m${s}\x1b[0m`;
const red = (s: string) => `\x1b[31m${s}\x1b[0m`;
const magenta = (s: string) => `\x1b[35m${s}\x1b[0m`;
// TODO(dotfiles-99s.9): rename linear()→beads() and drop ANSI hyperlinks.
const linear = (msg: string) => `  ${magenta("[Beads]")} ${msg}`;

async function main() {
  console.log("");
  const title = "AFK Ralph — Autonomous Issue Runner";
  const pad = 6;
  const inner = pad + title.length + pad;
  console.log(orange(`  ╔${"═".repeat(inner)}╗`));
  console.log(
    orange(`  ║${" ".repeat(pad)}`) +
      bold(title) +
      orange(`${" ".repeat(pad)}║`),
  );
  console.log(orange(`  ╚${"═".repeat(inner)}╝`));
  console.log("");

  const { model, effort } = await promptModelAndEffort();
  const mode = await promptMode();
  const runMode = await promptRunMode();
  log.info(
    `Model: ${model}  Effort: ${effort}  Mode: ${mode}  Run: ${runMode}`,
  );

  // --- Epic selection ---
  const epicSpin = spinner();
  epicSpin.start("Loading open beads epics");
  const epics = await listOpenEpics();
  epicSpin.stop(`Found ${epics.length} open epic(s)`);

  if (epics.length === 0) {
    log.error("No open epics found. Create one with `bd create --type epic ...`.");
    process.exit(1);
  }

  const selectedEpicId = ensure(
    await select<string>({
      message: "Select an epic to work on:",
      options: epics.map((e) => ({
        label: `${e.id}: ${e.title}`,
        value: e.id,
      })),
    }),
  );
  const epic = epics.find((e) => e.id === selectedEpicId)!;

  console.log(cyan(`\n  Epic ${bold(epic.id)}: ${epic.title}`));

  // --- Reset stale in_progress AI children ---
  // A prior orchestrator run may have crashed mid-sub-issue, leaving a child
  // stuck in `in_progress`. `bd ready` excludes `in_progress`, so without this
  // step the child would be invisible to the main loop. Flip any such children
  // back to `open` and push the batch once.
  const stale = await listChildrenByStatus(epic.id, "AI", "in_progress");
  if (stale.length > 0) {
    for (const issue of stale) {
      await resetStatus(issue.id, "open");
      console.log(
        linear(`Reset stale in_progress → open: ${issue.id}: ${issue.title}`),
      );
    }
    const pushProc = Bun.spawn(["bd", "dolt", "push"], {
      stdout: "pipe",
      stderr: "pipe",
    });
    const pushExit = await pushProc.exited;
    if (pushExit !== 0) {
      const pushErr = await new Response(pushProc.stderr).text();
      log.warn(`bd dolt push after reset failed: ${pushErr.trim()}`);
    }
  }

  // --- Branch setup ---
  const branchName = branchNameForEpic({ id: epic.id, title: epic.title });
  let baseBranch = "";
  if (mode === "code") {
    const currentBranch = await getCurrentBranch();
    baseBranch = currentBranch === branchName ? "master" : currentBranch;
    console.log(
      dim(`  Using epic branch → ${branchName} (base: ${baseBranch})`),
    );
    await checkoutBranch(branchName);
  } else {
    console.log(dim(`  Investigate mode — no branch checkout or git ops`));
  }

  // --- Iterate sub-issues ---
  let allComplete = false;
  while (true) {
    const remaining: BdIssue[] = await listReadyChildren(epic.id, "AI");
    if (remaining.length === 0) {
      console.log(green("\n  No ready AI-labeled sub-issues. All done!"));
      allComplete = true;
      break;
    }

    console.log(orange(`\n${"═".repeat(60)}`));
    console.log(yellow(`  ${remaining.length} ready sub-issue(s)`));
    console.log(orange(`${"═".repeat(60)}`));
    for (const issue of remaining) {
      console.log(
        `  ${cyan(issue.id)}: ${issue.title} ${dim(`[${issue.status}]`)}`,
      );
    }

    // `bd ready` returns blocker-aware ordering; pick the top item.
    const target = remaining[0]!;
    console.log(orange(`\n${"─".repeat(60)}`));
    console.log(
      `  ${orange("▶")} ${bold("Working on:")} ${cyan(target.id)}: ${target.title}`,
    );
    console.log(orange(`${"─".repeat(60)}`));
    console.log(linear(`Sub-agent will claim via 'bd update ${target.id} --claim'\n`));

    // Read (creating if absent) the on-disk progress doc for this epic and
    // inject prior entries into the sub-agent's prompt. The sub-agent itself
    // appends its final status block to the same file before pushing — see
    // prompt-implement-issue.md.
    await progressDoc.ensure(epic.id, epic.title);
    const progressContent = await progressDoc.read(epic.id);
    const progressSection = progressDoc.buildProgressSection(progressContent);

    // Beads-comments injection is deferred to dotfiles-99s.6.
    const issueComments: string[] = [];

    const result = await runClaude(
      epic.title,
      (epic.description as string) ?? "",
      progressSection,
      {
        identifier: target.id,
        title: target.title,
        description: (target.description as string) ?? "",
        comments: issueComments,
      },
      model,
      effort,
      mode,
    );

    if (result.success) {
      const entryBody = (result.resultText ?? "").trim();
      const parsed = parseAgentStatus(entryBody);
      if (parsed === "missing") {
        console.error(
          yellow(
            `  ! ${target.id} response missing **Status:** marker — treating as blocked`,
          ),
        );
      }
      const agentStatus: "completed" | "blocked" =
        parsed === "completed" ? "completed" : "blocked";

      // Cross-check the sub-agent's self-reported marker against the
      // authoritative bd status. Runs in both code and investigate modes;
      // warnings are non-fatal so the loop continues. bd remains the source
      // of truth for downstream routing (e.g., the `in-review` label check).
      await verifyAgentStatusAgainstBd(target.id, target.title, agentStatus);

      // TODO(dotfiles-99s.7): Feedback-label PR-thread resolution.

      if (agentStatus === "completed") {
        console.log(
          green(`\n  ✔  ${target.id} completed successfully.\n`),
        );
      } else {
        console.log(
          yellow(`\n  ⚠  ${target.id} reported blocked.\n`),
        );
      }
      console.log(orange(`${"═".repeat(60)}\n`));
    } else {
      console.error(
        red(`\n  ✘ ${target.id} failed: ${result.error}`),
      );
      console.error(yellow("  Continuing to next sub-issue..."));
      console.error(orange(`${"═".repeat(60)}\n`));
    }

    if (runMode === "single") {
      console.log(yellow("  Single run — stopping after one sub-issue."));
      break;
    }
  }

  // --- PR creation/update (code mode only) ---
  // The sub-agent already pushed the branch per CLAUDE.md; the orchestrator
  // only creates or updates the PR.
  if (mode === "code") {
    try {
      const prSpin = spinner();
      prSpin.start("Creating/updating pull request");
      const prUrl = await createOrUpdatePullRequest(
        {
          identifier: epic.id,
          title: epic.title,
          description: (epic.description as string) ?? "",
        },
        branchName,
        baseBranch,
        model,
        effort,
      );
      prSpin.stop(`PR ready: ${prUrl}`);
    } catch (err: any) {
      log.error(`Failed to create/update PR: ${err.message}`);
    }
  }

  // --- Epic "in-review" label ---
  // Beads analog of Linear's "In Review" PRD state. If EVERY AI-labeled child
  // of the epic is now closed, tag the epic with `in-review` and sync to the
  // Dolt remote. A `bd list` with a comma-separated `--status` filter lets us
  // count all non-closed states (open, in_progress, blocked, deferred) in one
  // call; if that count is 0, the epic is fully done.
  try {
    const nonClosed = await listChildrenByStatus(
      epic.id,
      "AI",
      "open,in_progress,blocked,deferred",
    );
    if (nonClosed.length === 0) {
      await addLabel(epic.id, "in-review");
      await doltPush();
      console.log(linear(`Added 'in-review' label to ${epic.id} and pushed.`));
    } else {
      console.log(
        linear(
          `${nonClosed.length} AI child(ren) not closed — skipping 'in-review' label.`,
        ),
      );
    }
  } catch (err: any) {
    log.warn(`Failed to apply 'in-review' label: ${err.message}`);
  }

  const doneText = allComplete ? "Done!" : "Iteration complete";
  const donePad = Math.floor((inner - doneText.length) / 2);
  const donePadR = inner - doneText.length - donePad;
  console.log(orange(`\n  ╔${"═".repeat(inner)}╗`));
  console.log(
    orange(`  ║${" ".repeat(donePad)}`) +
      green(bold(doneText)) +
      orange(`${" ".repeat(donePadR)}║`),
  );
  console.log(orange(`  ╚${"═".repeat(inner)}╝`));
  console.log(cyan(`  ${epic.id}: ${epic.title}`));
}

main().catch((err) => {
  console.error(red("\n  ✘ Uncaught error:"));
  if (err instanceof Error) {
    console.error(red(`  ${err.message}`));
    if (err.stack) console.error(dim(err.stack));
  } else {
    console.error(err);
  }
  const cause = (err as any)?.cause;
  if (cause) console.error(red("  Cause:"), cause);
  process.exit(1);
});
