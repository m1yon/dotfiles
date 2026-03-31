#! /usr/bin/env bun
// ---
// description: Run Claude in a loop to complete Linear PRD sub-issues automatically
// ---
import { LinearClient, type Issue } from "@linear/sdk";
import { select } from "@inquirer/prompts";
import { query } from "@anthropic-ai/claude-agent-sdk";

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

// --- Git Module ---

async function checkoutBranch(branchName: string): Promise<void> {
  // Try to check out existing branch first, otherwise create it
  const checkout = Bun.spawn(["git", "checkout", branchName], {
    stdout: "pipe",
    stderr: "pipe",
  });
  if ((await checkout.exited) === 0) {
    console.log(`Checked out existing branch: ${branchName}`);
    return;
  }

  const create = Bun.spawn(["git", "checkout", "-b", branchName], {
    stdout: "pipe",
    stderr: "pipe",
  });
  if ((await create.exited) !== 0) {
    const stderr = await new Response(create.stderr).text();
    throw new Error(`Failed to create branch ${branchName}: ${stderr.trim()}`);
  }
  console.log(`Created and checked out branch: ${branchName}`);
}

// --- Claude Orchestration ---

async function runClaude(
  prdTitle: string,
  prdDescription: string,
  subIssues: { identifier: string; title: string; description: string; comments: string[] }[],
): Promise<{ success: boolean; error?: string }> {
  const issueList = subIssues
    .map(
      (i) =>
        `- ${i.identifier}: ${i.title}\n  Description: ${i.description || "(none)"}\n  Comments: ${i.comments.length > 0 ? i.comments.join("\n  ") : "(none)"}`,
    )
    .join("\n");

  const prompt = `# PRD: ${prdTitle}

${prdDescription}

# Remaining Sub-Issues (in priority order)

${issueList}

# Instructions

Pick the SINGLE highest-priority sub-issue from the list above and complete it.

Priority rules:
1. Critical bugfixes
2. Tracer bullets (tiny end-to-end slices that validate architecture)
3. Polish and quick wins
4. Refactors

Explore the repo, understand the codebase, then implement the solution.

When done, make a single git commit with this format:
RALPH: <description> (<LINEAR-ID>)

Include in the commit body:
- Key decisions made
- Files changed
- Blockers or notes for next iteration

ONLY WORK ON A SINGLE SUB-ISSUE.`;

  try {
    for await (const message of query({
      prompt,
      options: {
        cwd: process.cwd(),
        allowedTools: ["Read", "Edit", "Write", "Bash", "Glob", "Grep"],
        permissionMode: "bypassPermissions",
        maxTurns: 100,
        settingSources: ["project"],
      },
    })) {
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

// --- Main ---

async function main() {
  const client = getLinearClient();

  // Fetch PRD issues
  const prds = await fetchPrdIssues(client);
  if (prds.length === 0) {
    console.error("No PRD issues found assigned to you on MECA Therapies.");
    process.exit(1);
  }

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

  const stateMap = await getStateMap(client, team.id);
  const inProgressId = stateMap.get("In Progress");
  const completedId = stateMap.get("Completed");
  const reviewId = stateMap.get("Review");

  if (!inProgressId || !completedId || !reviewId) {
    console.error(
      `Missing workflow states. Found: ${[...stateMap.keys()].join(", ")}`,
    );
    process.exit(1);
  }

  // Set PRD to In Progress
  await setIssueStatus(client, prd.id, inProgressId);
  console.log(`\nPRD "${prd.identifier}: ${prd.title}" set to In Progress\n`);

  // Iterate through sub-issues
  while (true) {
    const remaining = await fetchRemainingChildren(client, prd.id);
    if (remaining.length === 0) {
      console.log("\nAll sub-issues complete!");
      break;
    }

    console.log(`\n${remaining.length} sub-issue(s) remaining:`);
    for (const issue of remaining) {
      const state = await issue.state;
      console.log(
        `  ${issue.identifier}: ${issue.title} [${state?.name ?? "unknown"}]`,
      );
    }

    // Build sub-issue details for Claude's prompt
    const subIssueDetails = await Promise.all(
      remaining.map(async (issue) => {
        const details = await getIssueDetails(issue);
        return {
          identifier: issue.identifier,
          title: issue.title,
          description: details.description,
          comments: details.comments,
          id: issue.id,
          branchName: issue.branchName,
        };
      }),
    );

    // The first sub-issue (highest priority) is the one we expect Claude to pick
    const target = subIssueDetails[0];
    if (!target) throw new Error("Expected at least one sub-issue but found none");
    console.log(`\nExpecting Claude to work on: ${target.identifier}: ${target.title}`);

    // Checkout the Linear-generated branch
    await checkoutBranch(target.branchName);

    // Set target sub-issue to In Progress
    await setIssueStatus(client, target.id, inProgressId);
    console.log(`Set ${target.identifier} to In Progress\n`);

    // Run Claude
    const result = await runClaude(
      prd.title,
      prd.description ?? "",
      subIssueDetails,
    );

    if (result.success) {
      await setIssueStatus(client, target.id, completedId);
      console.log(`\n${target.identifier} completed successfully.`);
    } else {
      console.error(`\n${target.identifier} failed: ${result.error}`);
      console.error("Leaving issue In Progress, continuing to next...");
    }
  }

  // Set PRD to Review
  await setIssueStatus(client, prd.id, reviewId);
  console.log(`\nPRD "${prd.identifier}: ${prd.title}" set to Review. Done!`);
}

main();
