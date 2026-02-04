#! /usr/bin/env bun
import { Octokit } from "octokit";
import yargs from "yargs";
import { hideBin } from "yargs/helpers";

async function getRepoInfo(): Promise<{ owner: string; repo: string }> {
  const proc = Bun.spawn(["gh", "repo", "view", "--json", "owner,name"], {
    stdout: "pipe",
    stderr: "pipe",
  });
  const output = await new Response(proc.stdout).text();
  const exitCode = await proc.exited;

  if (exitCode !== 0) {
    throw new Error("Failed to get repo info. Are you in a GitHub repository?");
  }

  const data = JSON.parse(output);
  return { owner: data.owner.login, repo: data.name };
}

async function getAuthToken(): Promise<string> {
  const proc = Bun.spawn(["gh", "auth", "token"], {
    stdout: "pipe",
    stderr: "pipe",
  });
  const output = await new Response(proc.stdout).text();
  const exitCode = await proc.exited;

  if (exitCode !== 0) {
    throw new Error(
      "Failed to get auth token. Are you logged in with `gh auth login`?",
    );
  }

  return output.trim();
}

async function getCurrentPrNumber(): Promise<number> {
  const proc = Bun.spawn(["gh", "pr", "view", "--json", "number"], {
    stdout: "pipe",
    stderr: "pipe",
  });
  const output = await new Response(proc.stdout).text();
  const exitCode = await proc.exited;

  if (exitCode !== 0) {
    throw new Error(
      "Failed to get PR number. Is the current branch associated with a pull request?",
    );
  }

  const data = JSON.parse(output);
  return data.number;
}

async function getFileContentAtCommit(
  octokit: Octokit,
  owner: string,
  repo: string,
  commitSha: string,
  path: string,
): Promise<string | null> {
  try {
    const response = await octokit.rest.repos.getContent({
      owner,
      repo,
      path,
      ref: commitSha,
    });

    if ("content" in response.data && response.data.type === "file") {
      return Buffer.from(response.data.content, "base64").toString("utf-8");
    }
    return null;
  } catch {
    return null;
  }
}

function extractLines(
  content: string,
  startLine: number,
  endLine: number,
): string {
  const lines = content.split("\n");
  // Lines are 1-indexed from GitHub
  return lines.slice(startLine - 1, endLine).join("\n");
}

async function getPrFeedback(prNumber: number) {
  const authToken = await getAuthToken();
  const octokit = new Octokit({ auth: authToken });
  const { owner, repo } = await getRepoInfo();

  const query = `
    query($owner: String!, $name: String!, $number: Int!) {
      repository(owner: $owner, name: $name) {
        pullRequest(number: $number) {
          headRefOid
          # 1. General Timeline Comments (issue comments - not inline code comments)
          comments(last: 100) {
            nodes {
              id
              databaseId
              author { login }
              body
              createdAt
              url
            }
          }
          # 2. Reviews (Summaries only - inline comments fetched via reviewThreads)
          reviews(last: 50) {
            nodes {
              author { login }
              body # The summary text
              state
              submittedAt
            }
          }
          # 3. Review Threads (Inline Comments with resolved status)
          reviewThreads(last: 100) {
            nodes {
              isResolved
              comments(last: 50) {
                nodes {
                  id
                  databaseId
                  author { login }
                  body
                  path
                  line
                  startLine
                  originalLine
                  originalStartLine
                  createdAt
                  url
                }
              }
            }
          }
        }
      }
    }
  `;

  const response: any = await octokit.graphql(query, {
    owner,
    name: repo,
    number: prNumber,
  });

  const pr = response.repository.pullRequest;
  const headCommitSha = pr.headRefOid;

  // --- PROCESSING & FILTERING ---

  // 1. Flatten General Comments (these are issue comments, reply via issues API)
  const generalComments = pr.comments.nodes.map((c: any) => ({
    type: "General Comment",
    commentType: "issue" as const,
    commentId: c.databaseId,
    user: c.author.login,
    body: c.body,
    date: c.createdAt,
    url: c.url,
  }));

  // Cache for file contents to avoid fetching the same file multiple times
  const fileContentCache: Map<string, string | null> = new Map();

  async function getFileContent(path: string): Promise<string | null> {
    if (fileContentCache.has(path)) {
      return fileContentCache.get(path)!;
    }
    const content = await getFileContentAtCommit(
      octokit,
      owner,
      repo,
      headCommitSha,
      path,
    );
    fileContentCache.set(path, content);
    return content;
  }

  // 2. Flatten Reviews (summaries only)
  const reviewData: any[] = [];

  for (const review of pr.reviews.nodes) {
    // Add the Review Summary (if it has text) - these cannot be replied to directly
    if (review.body && review.body !== "") {
      reviewData.push({
        type: `Review (${review.state})`,
        commentType: null, // Review summaries cannot be replied to
        commentId: null,
        user: review.author.login,
        body: review.body,
        date: review.submittedAt,
        url: null,
      });
    }
  }

  // 3. Flatten Review Threads (Inline Comments) - only include unresolved threads
  for (const thread of pr.reviewThreads.nodes) {
    // Skip resolved threads
    if (thread.isResolved) {
      continue;
    }

    // Get the first comment in the thread (the original review comment)
    // We only include the first comment as that's the actionable feedback
    const comment = thread.comments.nodes[0];
    if (!comment) {
      continue;
    }

    // Determine line range for the comment
    // GitHub uses 'line' for single-line comments, 'startLine' and 'line' for multi-line
    const endLine = comment.line || comment.originalLine;
    const startLine = comment.startLine || comment.originalStartLine || endLine;
    const isMultiLine = startLine && endLine && startLine !== endLine;

    // Fetch the referenced code
    let referencedCode: string | undefined;
    if (comment.path && endLine) {
      const fileContent = await getFileContent(comment.path);
      if (fileContent) {
        const actualStartLine = isMultiLine ? startLine : endLine;
        referencedCode = extractLines(
          fileContent,
          actualStartLine,
          endLine,
        ).replace(/[\t\n]/g, " ");
      }
    }

    reviewData.push({
      type: `Inline Code`,
      commentType: "review" as const,
      commentId: comment.databaseId,
      user: comment.author.login,
      body: comment.body,
      path: comment.path,
      line: isMultiLine ? undefined : endLine,
      lineRange: isMultiLine ? { start: startLine, end: endLine } : undefined,
      referencedCode,
      date: comment.createdAt,
      url: comment.url,
    });
  }

  // 3. Combine, Filter, and Sort
  const allInteraction = [...generalComments, ...reviewData]
    .filter(
      (item) => item.user !== "coderabbitai" || item.commentType === "review",
    ) // <--- The Filter
    .sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime());

  // 4. Output
  console.log(JSON.stringify(allInteraction, null, 2));
}

async function replyToComment(
  prNumber: number,
  commentId: number,
  commentType: "review" | "issue",
  body: string,
) {
  const authToken = await getAuthToken();
  const octokit = new Octokit({ auth: authToken });
  const { owner, repo } = await getRepoInfo();

  if (commentType === "review") {
    // Reply to an inline code review comment
    const response = await octokit.rest.pulls.createReplyForReviewComment({
      owner,
      repo,
      pull_number: prNumber,
      comment_id: commentId,
      body,
    });
    console.log(
      JSON.stringify(
        {
          success: true,
          url: response.data.html_url,
          id: response.data.id,
        },
        null,
        2,
      ),
    );
  } else {
    // Reply to a general issue comment (create a new issue comment)
    // Note: GitHub doesn't have threaded replies for issue comments,
    // so we create a new comment that quotes/references the original
    const response = await octokit.rest.issues.createComment({
      owner,
      repo,
      issue_number: prNumber,
      body,
    });
    console.log(
      JSON.stringify(
        {
          success: true,
          url: response.data.html_url,
          id: response.data.id,
        },
        null,
        2,
      ),
    );
  }
}

yargs(hideBin(process.argv))
  .scriptName("agh")
  .usage("$0 <command> [options]")
  .command(
    "get-pr-feedback",
    "Get feedback comments from a pull request (infers PR from current branch)",
    () => {},
    async () => {
      const prNumber = await getCurrentPrNumber();
      await getPrFeedback(prNumber);
    },
  )
  .command(
    "reply-to-comment",
    "Reply to a comment on a pull request",
    (yargs) => {
      return yargs
        .option("comment-id", {
          alias: "c",
          type: "number",
          description:
            "The comment ID to reply to (from get-pr-feedback output)",
          demandOption: true,
        })
        .option("type", {
          alias: "t",
          type: "string",
          choices: ["review", "issue"] as const,
          description:
            "The type of comment: 'review' for inline code comments, 'issue' for general comments",
          demandOption: true,
        })
        .option("body", {
          alias: "b",
          type: "string",
          description: "The reply message body",
          demandOption: true,
        });
    },
    async (argv) => {
      const prNumber = await getCurrentPrNumber();
      await replyToComment(
        prNumber,
        argv["comment-id"],
        argv.type as "review" | "issue",
        argv.body,
      );
    },
  )
  .demandCommand(1, "You need to specify a command")
  .help()
  .parseAsync();
