#! /usr/bin/env bun
// ---
// description: Run Claude in a loop to complete Linear PRD sub-issues automatically
// ---
import { LinearClient, type Issue } from "@linear/sdk";
import { select } from "@inquirer/prompts";
import { query } from "@anthropic-ai/claude-agent-sdk";
import { logQueryMessage } from "./log-query-message";
import { Octokit } from "octokit";

const CLAUDE_PATH = Bun.spawnSync(["which", "claude"]).stdout.toString().trim();
if (!CLAUDE_PATH) {
  console.error("ERROR: claude not found on PATH");
  process.exit(1);
}

// --- Linear Module ---

function getLinearClient(): LinearClient {
  const apiKey = process.env.LINEAR_API_KEY;
  if (!apiKey) {
    console.error("ERROR: LINEAR_API_KEY environment variable is required");
    process.exit(1);
  }
  return new LinearClient({ apiKey });
}

async function getStateMap(
  client: LinearClient,
  teamId: string,
): Promise<Map<string, string>> {
  const team = await client.team(teamId);
  const states = await team.states();
  const map = new Map<string, string>();
  for (const s of states.nodes) {
    map.set(s.name, s.id);
  }
  return map;
}

async function setIssueStatus(
  client: LinearClient,
  issueId: string,
  stateId: string,
): Promise<void> {
  await client.updateIssue(issueId, { stateId });
}

async function fetchPrdIssues(client: LinearClient): Promise<Issue[]> {
  const me = await client.viewer;
  const prdIssues = await me.assignedIssues({
    filter: {
      team: { name: { eq: "MECA Therapies" } },
      labels: { name: { eq: "PRD" } },
      state: { type: { neq: "completed" } },
    },
  });
  return prdIssues.nodes;
}

async function fetchRemainingChildren(
  client: LinearClient,
  prdId: string,
): Promise<Issue[]> {
  const prd = await client.issue(prdId);
  const children = await prd.children();
  const remaining: Issue[] = [];

  for (const child of children.nodes) {
    const state = await child.state;
    if (state?.type !== "completed" && state?.type !== "canceled") {
      remaining.push(child);
    }
  }

  // Lower priority number = higher priority, 0 = no priority (sort last)
  remaining.sort((a, b) => {
    const pa = a.priority === 0 ? 99 : (a.priority ?? 99);
    const pb = b.priority === 0 ? 99 : (b.priority ?? 99);
    return pa - pb;
  });

  return remaining;
}

async function getIssueDetails(
  issue: Issue,
): Promise<{ description: string; comments: string[] }> {
  const comments = await issue.comments();
  return {
    description: issue.description ?? "",
    comments: comments.nodes.map((c) => c.body),
  };
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

async function pushBranch(branchName: string): Promise<void> {
  const proc = Bun.spawn(["git", "push", "-u", "origin", branchName], {
    stdout: "pipe",
    stderr: "pipe",
  });
  if ((await proc.exited) !== 0) {
    const stderr = await new Response(proc.stderr).text();
    throw new Error(`Failed to push branch: ${stderr.trim()}`);
  }
}

async function generatePrBody(
  prd: { identifier: string; title: string; url: string; description: string },
  baseBranch: string,
): Promise<string> {
  const prompt = `You are writing a GitHub pull request description. Look at the commits on this branch (compared to ${baseBranch}) using git log and git diff, then write a concise PR body in markdown.

The PR implements a Linear PRD:
- Identifier: ${prd.identifier}
- Title: ${prd.title}
- URL: ${prd.url}
- Description: ${prd.description || "(none)"}

Output ONLY the PR body markdown, nothing else. Focus on module and interface changes, NOT file-by-file diffs. Use this structure:

## Summary
One or two sentences on what this PR delivers end-to-end.

## Interface Changes
For each module or boundary that was added or modified, show a before/after using GitHub markdown diff blocks. Only show the public interface (types, function signatures, route definitions, schema shapes) — not implementation. For new modules, omit the before. Example format:

\`\`\`diff
- function fetchUser(id: string): Promise<User>
+ function fetchUser(id: string, opts?: FetchOptions): Promise<UserWithRole>
\`\`\`

Do NOT list individual file paths or line-level implementation changes.

## Key Decisions
Bulleted list of non-obvious implementation decisions (e.g. why a particular boundary was drawn, trade-offs made, patterns chosen).

## Testing
How the changes are verified — which boundaries are tested and how.

---
Linear: ${prd.url}`;

  let resultText = "";
  for await (const message of query({
    prompt,
    options: {
      cwd: process.cwd(),
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
    `## ${prd.identifier}: ${prd.title}\n\n${prd.description ?? ""}\n\nLinear: ${prd.url}`
  );
}

async function createOrUpdatePullRequest(
  prd: { identifier: string; title: string; url: string; description: string },
  branchName: string,
  baseBranch: string,
): Promise<string> {
  const authToken = await getAuthToken();
  const octokit = new Octokit({ auth: authToken });
  const { owner, repo } = await getRepoInfo();

  const title = `${prd.identifier}: ${prd.title}`;
  const body = await generatePrBody(prd, baseBranch);

  // Check for existing PR on this branch
  const { data: existing } = await octokit.rest.pulls.list({
    owner,
    repo,
    head: `${owner}:${branchName}`,
    state: "open",
  });

  if (existing.length > 0) {
    const pr = existing[0]!;
    await octokit.rest.pulls.update({
      owner,
      repo,
      pull_number: pr.number,
      title,
      body,
    });
    return pr.html_url;
  }

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
  prdTitle: string,
  prdDescription: string,
  issue: {
    identifier: string;
    title: string;
    description: string;
    comments: string[];
  },
): Promise<{ success: boolean; error?: string }> {
  const prompt = `# PRD: ${prdTitle}

${prdDescription}

# Issue: ${issue.identifier} — ${issue.title}

${issue.description || "(no description)"}

${issue.comments.length > 0 ? `## Comments\n\n${issue.comments.join("\n\n")}` : ""}

# Instructions

Implement this issue. Explore the repo, understand the codebase, then implement the solution.

Each sub-issue gets its own commit. When done, make a single git commit for THIS issue with this format:
${issue.identifier}: <description>

Include in the commit body (markdown is fine):
- Key decisions made
- Files changed
- Blockers or notes for next iteration

Do NOT squash multiple sub-issues into one commit. Do NOT push to git — the orchestrator handles that.`;

  try {
    for await (const message of query({
      prompt,
      options: {
        cwd: process.cwd(),
        allowedTools: ["Read", "Edit", "Write", "Bash", "Glob", "Grep"],
        permissionMode: "bypassPermissions",
        allowDangerouslySkipPermissions: true,
        maxTurns: 100,
        settingSources: ["project"],
        pathToClaudeCodeExecutable: CLAUDE_PATH,
        stderr: (data: string) => console.log(data),
      },
    })) {
      logQueryMessage(message);
      if (message.type === "result") {
        if (message.subtype === "success") {
          return { success: true };
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

async function getLastCommitBody(): Promise<string> {
  const proc = Bun.spawn(["git", "log", "-1", "--format=%b"], {
    stdout: "pipe",
    stderr: "pipe",
  });
  await proc.exited;
  return (await new Response(proc.stdout).text()).trim();
}

async function commentOnIssue(
  client: LinearClient,
  issueId: string,
  body: string,
): Promise<void> {
  await client.createComment({ issueId, body });
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
const link = (text: string, url: string) =>
  `\x1b]8;;${url}\x1b\\${text}\x1b]8;;\x1b\\`;
const linear = (msg: string) => `  ${magenta("[Linear]")} ${msg}`;

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

  console.log(dim("  Connecting to Linear..."));
  const client = getLinearClient();

  // Fetch PRD issues
  const prds = await fetchPrdIssues(client);
  if (prds.length === 0) {
    console.error("No PRD issues found assigned to you on MECA Therapies.");
    process.exit(1);
  }
  console.log(green(`  Found ${prds.length} PRD(s)\n`));

  // Interactive PRD selection
  const selectedId = await select({
    message: "Select a PRD to work on:",
    choices: prds.map((prd) => ({
      name: `${prd.identifier}: ${prd.title}`,
      value: prd.id,
    })),
  });

  const prd = await client.issue(selectedId);
  const team = await prd.team;
  if (!team) {
    console.error("Could not resolve team for selected PRD.");
    process.exit(1);
  }

  console.log(dim("\n  Loading workflow states..."));
  const stateMap = await getStateMap(client, team.id);
  const inProgressId = stateMap.get("In Progress");
  const completedId = stateMap.get("Completed");
  const reviewId = stateMap.get("In Review");

  if (!inProgressId || !completedId || !reviewId) {
    console.error(
      `Missing workflow states. Found: ${[...stateMap.keys()].join(", ")}`,
    );
    process.exit(1);
  }

  // Set PRD to In Progress
  const prdPrevState = (await (await prd.state)?.name) ?? "Unknown";
  await setIssueStatus(client, prd.id, inProgressId);
  console.log(
    cyan(`\n  PRD ${link(bold(prd.identifier), prd.url)}: ${prd.title}`),
  );
  console.log(linear(`Status: ${prdPrevState} → In Progress`));

  // Checkout PRD branch for all sub-issues
  const currentBranch = await getCurrentBranch();
  const baseBranch = currentBranch === prd.branchName ? "dev" : currentBranch;
  console.log(
    dim(`  Using PRD branch → ${prd.branchName} (base: ${baseBranch})`),
  );
  await checkoutBranch(prd.branchName);
  console.log("");

  // Iterate through sub-issues
  while (true) {
    const remaining = await fetchRemainingChildren(client, prd.id);
    if (remaining.length === 0) {
      console.log(green("\n  All sub-issues complete!"));
      break;
    }

    console.log(orange(`\n${"═".repeat(60)}`));
    console.log(yellow(`  ${remaining.length} sub-issue(s) remaining`));
    console.log(orange(`${"═".repeat(60)}`));
    for (const issue of remaining) {
      const state = await issue.state;
      console.log(
        `  ${link(cyan(issue.identifier), issue.url)}: ${issue.title} ${dim(`[${state?.name ?? "unknown"}]`)}`,
      );
    }

    // Pick the highest-priority sub-issue
    const target = remaining[0]!;
    const details = await getIssueDetails(target);
    console.log(orange(`\n${"─".repeat(60)}`));
    console.log(
      `  ${orange("▶")} ${bold("Working on:")} ${link(cyan(target.identifier), target.url)}: ${target.title}`,
    );
    console.log(orange(`${"─".repeat(60)}`));

    // Set target sub-issue to In Progress
    await setIssueStatus(client, target.id, inProgressId);
    console.log(linear("Status: Todo → In Progress\n"));

    // Run Claude
    const result = await runClaude(prd.title, prd.description ?? "", {
      identifier: target.identifier,
      title: target.title,
      description: details.description,
      comments: details.comments,
    });

    if (result.success) {
      const commitBody = await getLastCommitBody();
      if (commitBody) {
        await commentOnIssue(client, target.id, commitBody);
        console.log(
          linear(`Comment posted on ${link(target.identifier, target.url)}`),
        );
      }

      // Push after each sub-issue
      console.log(dim(`  Pushing ${prd.branchName}...`));
      await pushBranch(prd.branchName);
      console.log(green("  Pushed."));

      await setIssueStatus(client, target.id, completedId);
      console.log(
        green(
          `\n  ✔  ${link(target.identifier, target.url)} completed successfully.\n`,
        ),
      );
      console.log(linear("Status: In Progress → Completed"));
      console.log(orange(`${"═".repeat(60)}\n`));
    } else {
      console.error(
        red(
          `\n  ✘ ${link(target.identifier, target.url)} failed: ${result.error}`,
        ),
      );
      console.error(
        yellow("  Leaving issue In Progress, continuing to next..."),
      );
      console.error(orange(`${"═".repeat(60)}\n`));
    }
  }

  // Push branch and create PR
  console.log(dim("\n  Pushing branch to origin..."));
  await pushBranch(prd.branchName);
  console.log(green("  Branch pushed."));

  console.log(dim("  Generating PR body..."));
  try {
    const prUrl = await createOrUpdatePullRequest(
      {
        identifier: prd.identifier,
        title: prd.title,
        url: prd.url,
        description: prd.description ?? "",
      },
      prd.branchName,
      baseBranch,
    );
    console.log(green(`  PR ready: ${link(prUrl, prUrl)}`));
  } catch (err: any) {
    console.error(red(`  Failed to create/update PR: ${err.message}`));
  }

  // Set PRD to Review
  await setIssueStatus(client, prd.id, reviewId);
  const doneText = "Done!";
  const donePad = Math.floor((inner - doneText.length) / 2);
  const donePadR = inner - doneText.length - donePad;
  console.log(orange(`\n  ╔${"═".repeat(inner)}╗`));
  console.log(
    orange(`  ║${" ".repeat(donePad)}`) +
      green(bold(doneText)) +
      orange(`${" ".repeat(donePadR)}║`),
  );
  console.log(orange(`  ╚${"═".repeat(inner)}╝`));
  console.log(cyan(`  ${link(prd.identifier, prd.url)}: ${prd.title}`));
  console.log(linear("Status: In Progress → In Review"));
}

main();
