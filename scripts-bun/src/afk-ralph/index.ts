#! /usr/bin/env bun
// ---
// description: Run Claude in a loop to complete Linear PRD sub-issues automatically
// ---
import { LinearClient, type Issue } from "@linear/sdk";

interface RemainingChild {
  id: string;
  identifier: string;
  title: string;
  url: string;
  description: string;
  priority: number;
  stateName: string;
  stateType: string;
  labels: string[];
  comments: string[];
}
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

async function fetchTeams(client: LinearClient): Promise<{ id: string; name: string }[]> {
  const teams = await client.teams();
  return teams.nodes.map((t) => ({ id: t.id, name: t.name }));
}

async function fetchPrdIssues(client: LinearClient, teamName: string): Promise<Issue[]> {
  const me = await client.viewer;
  const prdIssues = await me.assignedIssues({
    filter: {
      team: { name: { eq: teamName } },
      labels: { name: { eq: "PRD" } },
      state: { type: { neq: "completed" } },
    },
  });
  return prdIssues.nodes;
}

async function fetchRemainingChildren(
  client: LinearClient,
  prdId: string,
): Promise<{ issues: RemainingChild[]; blockedIds: Set<string> }> {
  type RawChild = {
    id: string;
    identifier: string;
    title: string;
    url: string;
    description: string | null;
    priority: number;
    state: { name: string; type: string };
    labels: { nodes: Array<{ name: string }> };
    comments: { nodes: Array<{ body: string }> };
    inverseRelations: { nodes: Array<{ type: string; issue: { id: string } }> };
  };

  const { data } = await client.client.rawRequest<
    { issue: { children: { nodes: RawChild[] } } },
    { id: string }
  >(
    `query ($id: String!) {
      issue(id: $id) {
        children(first: 250) {
          nodes {
            id identifier title url description priority
            state { name type }
            labels { nodes { name } }
            comments { nodes { body } }
            inverseRelations { nodes { type issue { id } } }
          }
        }
      }
    }`,
    { id: prdId },
  );

  const nodes = data?.issue?.children?.nodes ?? [];
  const remaining: RemainingChild[] = nodes
    .filter(
      (c) =>
        c.state.type !== "completed" &&
        c.state.type !== "canceled" &&
        c.state.name !== "Blocked" &&
        c.labels.nodes.some((l) => l.name === "AI"),
    )
    .map((c) => ({
      id: c.id,
      identifier: c.identifier,
      title: c.title,
      url: c.url,
      description: c.description ?? "",
      priority: c.priority,
      stateName: c.state.name,
      stateType: c.state.type,
      labels: c.labels.nodes.map((l) => l.name),
      comments: c.comments.nodes.map((n) => n.body),
    }));

  const remainingIds = new Set(remaining.map((i) => i.id));
  const blockedIds = new Set<string>();
  for (const child of nodes) {
    if (!remainingIds.has(child.id)) continue;
    for (const rel of child.inverseRelations.nodes) {
      if (rel.type === "blocks" && remainingIds.has(rel.issue.id)) {
        blockedIds.add(child.id);
        break;
      }
    }
  }

  // Sort: unblocked first, then by priority (lower number = higher priority, 0 = no priority = last)
  remaining.sort((a, b) => {
    const aBlocked = blockedIds.has(a.id) ? 1 : 0;
    const bBlocked = blockedIds.has(b.id) ? 1 : 0;
    if (aBlocked !== bBlocked) return aBlocked - bBlocked;
    const pa = a.priority === 0 ? 99 : (a.priority ?? 99);
    const pb = b.priority === 0 ? 99 : (b.priority ?? 99);
    return pa - pb;
  });

  return { issues: remaining, blockedIds };
}

// --- Progress Document ---

function progressDocTitle(prdIdentifier: string): string {
  return `Progress: ${prdIdentifier}`;
}

async function findProgressDocId(
  client: LinearClient,
  prdId: string,
  prdIdentifier: string,
): Promise<string | null> {
  const { data } = await client.client.rawRequest<
    { issue: { documents: { nodes: Array<{ id: string; title: string }> } } },
    { id: string }
  >(
    `query ($id: String!) {
      issue(id: $id) {
        documents(first: 50) { nodes { id title } }
      }
    }`,
    { id: prdId },
  );
  const target = progressDocTitle(prdIdentifier);
  return data?.issue?.documents?.nodes.find((d) => d.title === target)?.id ?? null;
}

async function ensureProgressDoc(
  client: LinearClient,
  prd: { id: string; identifier: string; title: string },
): Promise<string> {
  const existing = await findProgressDocId(client, prd.id, prd.identifier);
  if (existing) return existing;

  const initial = `# Progress — ${prd.identifier}: ${prd.title}\n\nRunning log for afk-ralph iterations. Each sub-issue agent appends one entry. Concise — this is context for the next agent, not documentation.\n\n---\n`;

  const { data } = await client.client.rawRequest<
    { documentCreate: { success: boolean; document: { id: string } } },
    { input: { title: string; content: string; issueId: string } }
  >(
    `mutation ($input: DocumentCreateInput!) {
      documentCreate(input: $input) {
        success
        document { id }
      }
    }`,
    {
      input: {
        title: progressDocTitle(prd.identifier),
        content: initial,
        issueId: prd.id,
      },
    },
  );
  const id = data?.documentCreate?.document?.id;
  if (!id) throw new Error("Failed to create progress document");
  return id;
}

async function fetchProgressDocContent(
  client: LinearClient,
  docId: string,
): Promise<string> {
  const { data } = await client.client.rawRequest<
    { document: { content: string } },
    { id: string }
  >(
    `query ($id: String!) {
      document(id: $id) { content }
    }`,
    { id: docId },
  );
  return data?.document?.content ?? "";
}

async function updateProgressDocContent(
  client: LinearClient,
  docId: string,
  content: string,
): Promise<void> {
  await client.client.rawRequest<
    { documentUpdate: { success: boolean } },
    { id: string; input: { content: string } }
  >(
    `mutation ($id: String!, $input: DocumentUpdateInput!) {
      documentUpdate(id: $id, input: $input) { success }
    }`,
    { id: docId, input: { content } },
  );
}

async function appendProgressEntry(
  client: LinearClient,
  docId: string,
  entry: string,
): Promise<void> {
  const doAppend = async () => {
    const current = await fetchProgressDocContent(client, docId);
    const sep = current.endsWith("\n") ? "" : "\n";
    const next = `${current}${sep}\n${entry}\n\n---\n`;
    await updateProgressDocContent(client, docId, next);
  };
  try {
    await doAppend();
  } catch (err) {
    log.warn(`Progress doc append failed, retrying: ${err}`);
    try {
      await doAppend();
    } catch (err2) {
      log.warn(`Progress doc append failed again, continuing: ${err2}`);
    }
  }
}

function formatProgressEntry(
  issue: { identifier: string; title: string },
  status: string,
  body: string,
): string {
  const ts = new Date().toISOString().replace(/\.\d+Z$/, "Z");
  return `## ${issue.identifier}: ${issue.title}\n\n_${ts} · ${status}_\n\n${body}`;
}

function parseAgentStatus(resultText: string): "completed" | "blocked" | "missing" {
  const match = resultText.match(/\*\*Status:\*\*\s*(completed|blocked)/i);
  if (!match) return "missing";
  return match[1]!.toLowerCase() as "completed" | "blocked";
}

function buildProgressSection(docContent: string): string {
  const firstEntry = docContent.indexOf("\n## ");
  if (firstEntry === -1) return "";
  const entries = docContent.slice(firstEntry + 1).trim();
  if (!entries) return "";
  return `\n# Prior Progress\n\n${entries}\n`;
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
  model: string,
  effort: EffortLevel,
): Promise<string> {
  const prompt = loadPrompt("prompt-pr-body.md", {
    baseBranch,
    prdIdentifier: prd.identifier,
    prdTitle: prd.title,
    prdUrl: prd.url,
    prdDescription: prd.description || "(none)",
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
    `## ${prd.identifier}: ${prd.title}\n\n${prd.description ?? ""}\n\nLinear: ${prd.url}`
  );
}

async function createOrUpdatePullRequest(
  prd: { identifier: string; title: string; url: string; description: string },
  branchName: string,
  baseBranch: string,
  model: string,
  effort: EffortLevel,
): Promise<string> {
  const authToken = await getAuthToken();
  const octokit = new Octokit({ auth: authToken });
  const { owner, repo } = await getRepoInfo();

  const title = `${prd.identifier}: ${prd.title}`;

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
      const body = await generatePrBody(prd, baseBranch, model, effort);
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

  const body = await generatePrBody(prd, baseBranch, model, effort);
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
    prdTitle,
    prdDescription,
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

// --- Feedback Resolution ---

interface FeedbackMetadata {
  threadId: string | null;
  commentId: number;
  commentType: "review" | "issue";
  prNumber: number;
}

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

async function getShortCommitSha(): Promise<string> {
  const proc = Bun.spawn(["git", "log", "-1", "--format=%h"], {
    stdout: "pipe",
    stderr: "pipe",
  });
  await proc.exited;
  return (await new Response(proc.stdout).text()).trim();
}

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

  const { model, effort } = await promptModelAndEffort();
  const mode = await promptMode();
  const runMode = await promptRunMode();
  log.info(
    `Model: ${model}  Effort: ${effort}  Mode: ${mode}  Run: ${runMode}`,
  );

  const linearSpin = spinner();
  linearSpin.start("Connecting to Linear");
  const client = getLinearClient();
  const teams = await fetchTeams(client);
  linearSpin.stop(`Connected (${teams.length} team(s))`);

  if (teams.length === 0) {
    log.error("No teams found in Linear.");
    process.exit(1);
  }

  let teamName: string;
  if (teams.length === 1) {
    teamName = teams[0]!.name;
    log.info(`Team: ${teamName}`);
  } else {
    teamName = ensure(
      await select<string>({
        message: "Select a team:",
        options: teams.map((t) => ({ value: t.name, label: t.name })),
      }),
    );
  }

  const prdSpin = spinner();
  prdSpin.start(`Fetching PRDs for ${teamName}`);
  const prds = await fetchPrdIssues(client, teamName);
  if (prds.length === 0) {
    prdSpin.stop(`No PRD issues found on ${teamName}`);
    process.exit(1);
  }
  const choices = await Promise.all(
    prds.map(async (prd) => {
      const { issues: remaining } = await fetchRemainingChildren(client, prd.id);
      return {
        label: `${prd.identifier}: ${prd.title} (${remaining.length} incomplete sub-issues)`,
        value: prd.id,
      };
    }),
  );
  prdSpin.stop(`Found ${prds.length} PRD(s)`);

  const selectedId = ensure(
    await select<string>({
      message: "Select a PRD to work on:",
      options: choices,
    }),
  );

  const prd = await client.issue(selectedId);
  const team = await prd.team;
  if (!team) {
    log.error("Could not resolve team for selected PRD.");
    process.exit(1);
  }

  const stateSpin = spinner();
  stateSpin.start("Loading workflow states");
  const stateMap = await getStateMap(client, team.id);
  stateSpin.stop("Workflow states loaded");
  const inProgressId = stateMap.get("In Progress");
  const completedId = stateMap.get("Completed");
  const reviewId = stateMap.get("In Review");
  const blockedId = stateMap.get("Blocked");

  if (!inProgressId || !completedId || !reviewId || !blockedId) {
    log.error(
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

  // Checkout PRD branch for all sub-issues (code mode only)
  let baseBranch = "";
  if (mode === "code") {
    const currentBranch = await getCurrentBranch();
    baseBranch = currentBranch === prd.branchName ? "dev" : currentBranch;
    console.log(
      dim(`  Using PRD branch → ${prd.branchName} (base: ${baseBranch})`),
    );
    await checkoutBranch(prd.branchName);
  } else {
    console.log(dim(`  Investigate mode — no branch checkout or git ops`));
  }

  // Ensure progress document exists on the PRD
  const progressSpin = spinner();
  progressSpin.start("Ensuring progress document");
  const progressDocId = await ensureProgressDoc(client, {
    id: prd.id,
    identifier: prd.identifier,
    title: prd.title,
  });
  progressSpin.stop(`Progress document ready`);
  console.log("");

  // Iterate through sub-issues
  let allComplete = false;
  while (true) {
    const { issues: remaining, blockedIds } = await fetchRemainingChildren(client, prd.id);
    if (remaining.length === 0) {
      console.log(green("\n  All sub-issues complete!"));
      allComplete = true;
      break;
    }

    console.log(orange(`\n${"═".repeat(60)}`));
    console.log(yellow(`  ${remaining.length} sub-issue(s) remaining`));
    console.log(orange(`${"═".repeat(60)}`));
    for (const issue of remaining) {
      const blocked = blockedIds.has(issue.id) ? red(" [blocked]") : "";
      console.log(
        `  ${link(cyan(issue.identifier), issue.url)}: ${issue.title} ${dim(`[${issue.stateName}]`)}${blocked}`,
      );
    }

    // Pick the highest-priority unblocked sub-issue
    const target = remaining[0]!;
    if (blockedIds.has(target.id)) {
      console.error(red(`\n  ✘ All remaining issues are blocked — cannot proceed`));
      process.exit(1);
    }
    console.log(orange(`\n${"─".repeat(60)}`));
    console.log(
      `  ${orange("▶")} ${bold("Working on:")} ${link(cyan(target.identifier), target.url)}: ${target.title}`,
    );
    console.log(orange(`${"─".repeat(60)}`));

    // Set target sub-issue to In Progress
    await setIssueStatus(client, target.id, inProgressId);
    console.log(linear("Status: Todo → In Progress\n"));

    // Fetch current progress doc content to inject into the prompt
    const progressContent = await fetchProgressDocContent(client, progressDocId);
    const progressSection = buildProgressSection(progressContent);

    // Run Claude
    const result = await runClaude(
      prd.title,
      prd.description ?? "",
      progressSection,
      {
        identifier: target.identifier,
        title: target.title,
        description: target.description,
        comments: target.comments,
      },
      model,
      effort,
      mode,
    );

    if (result.success) {
      const entryBody = (result.resultText ?? "").trim();
      if (!entryBody) {
        console.error(
          red(
            `\n  ✘ ${link(target.identifier, target.url)} produced no progress entry — aborting run`,
          ),
        );
        process.exit(1);
      }

      const parsed = parseAgentStatus(entryBody);
      if (parsed === "missing") {
        console.error(
          yellow(
            `  ! ${target.identifier} response missing **Status:** marker — treating as blocked`,
          ),
        );
      }
      const agentStatus: "completed" | "blocked" =
        parsed === "completed" ? "completed" : "blocked";

      await appendProgressEntry(
        client,
        progressDocId,
        formatProgressEntry(
          { identifier: target.identifier, title: target.title },
          agentStatus,
          entryBody,
        ),
      );
      console.log(linear(`Progress entry appended for ${target.identifier}`));

      if (mode === "code" && agentStatus === "completed") {
        // Push after each sub-issue
        const pushSpin = spinner();
        pushSpin.start(`Pushing ${prd.branchName}`);
        await pushBranch(prd.branchName);
        pushSpin.stop(`Pushed ${prd.branchName}`);

        // Resolve PR feedback if this is a Feedback-labeled issue
        if (target.labels.includes("Feedback")) {
          const feedbackMeta = parseFeedbackMetadata(target.description);
          if (feedbackMeta.length > 0) {
            const sha = await getShortCommitSha();
            const feedbackSpin = spinner();
            feedbackSpin.start(
              `Resolving ${feedbackMeta.length} PR feedback thread(s)`,
            );
            await resolveFeedbackOnGitHub(feedbackMeta, sha);
            feedbackSpin.stop("PR feedback resolved");
          }
        }
      }

      if (agentStatus === "completed") {
        await setIssueStatus(client, target.id, completedId);
        console.log(
          green(
            `\n  ✔  ${link(target.identifier, target.url)} completed successfully.\n`,
          ),
        );
        console.log(linear("Status: In Progress → Completed"));
      } else {
        await setIssueStatus(client, target.id, blockedId);
        console.log(
          yellow(
            `\n  ⚠  ${link(target.identifier, target.url)} could not be completed — marking Blocked.\n`,
          ),
        );
        console.log(linear("Status: In Progress → Blocked"));
      }
      console.log(orange(`${"═".repeat(60)}\n`));
    } else {
      console.error(
        red(
          `\n  ✘ ${link(target.identifier, target.url)} failed: ${result.error}`,
        ),
      );
      await appendProgressEntry(
        client,
        progressDocId,
        formatProgressEntry(
          { identifier: target.identifier, title: target.title },
          `failed: ${result.error ?? "unknown"}`,
          `*(Claude run failed. No progress entry produced.)*`,
        ),
      );
      await setIssueStatus(client, target.id, blockedId);
      console.error(linear("Status: In Progress → Blocked"));
      console.error(yellow("  Continuing to next sub-issue..."));
      console.error(orange(`${"═".repeat(60)}\n`));
    }

    if (runMode === "single") {
      console.log(yellow("  Single run — stopping after one sub-issue."));
      break;
    }
  }

  // Push branch and create PR (code mode only)
  if (mode === "code") {
    const finalPushSpin = spinner();
    finalPushSpin.start("Pushing branch to origin");
    await pushBranch(prd.branchName);
    finalPushSpin.stop("Branch pushed");

    try {
      const prSpin = spinner();
      prSpin.start("Creating/updating pull request");
      const prUrl = await createOrUpdatePullRequest(
        {
          identifier: prd.identifier,
          title: prd.title,
          url: prd.url,
          description: prd.description ?? "",
        },
        prd.branchName,
        baseBranch,
        model,
        effort,
      );
      prSpin.stop(`PR ready: ${link(prUrl, prUrl)}`);
    } catch (err: any) {
      log.error(`Failed to create/update PR: ${err.message}`);
    }
  }

  // Set PRD to Review only when all sub-issues are complete
  if (allComplete) {
    await setIssueStatus(client, prd.id, reviewId);
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
  console.log(cyan(`  ${link(prd.identifier, prd.url)}: ${prd.title}`));
  if (allComplete) {
    console.log(linear("Status: In Progress → In Review"));
  } else {
    console.log(linear("Status: In Progress (sub-issues remaining)"));
  }
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
  const errors = (err as any)?.errors;
  if (Array.isArray(errors)) {
    console.error(red("  GraphQL errors:"));
    for (const e of errors) console.error(red(`    - ${JSON.stringify(e)}`));
  }
  process.exit(1);
});
