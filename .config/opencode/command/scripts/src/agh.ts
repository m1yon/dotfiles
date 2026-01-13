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

function extractLines(content: string, startLine: number, endLine: number): string {
  const lines = content.split("\n");
  // Lines are 1-indexed from GitHub
  return lines.slice(startLine - 1, endLine).join("\n");
}

async function reactToComment(
  octokit: Octokit,
  owner: string,
  repo: string,
  commentId: number,
  commentType: "review" | "issue",
  reaction: "+1" | "eyes",
) {
  if (commentType === "review") {
    await octokit.rest.reactions.createForPullRequestReviewComment({
      owner,
      repo,
      comment_id: commentId,
      content: reaction,
    });
  } else {
    await octokit.rest.reactions.createForIssueComment({
      owner,
      repo,
      comment_id: commentId,
      content: reaction,
    });
  }
}

async function getCommentReactions(
  octokit: Octokit,
  owner: string,
  repo: string,
  commentId: number,
  commentType: "review" | "issue",
): Promise<string[]> {
  try {
    if (commentType === "review") {
      const response = await octokit.rest.reactions.listForPullRequestReviewComment({
        owner,
        repo,
        comment_id: commentId,
      });
      return response.data.map((r) => r.content);
    } else {
      const response = await octokit.rest.reactions.listForIssueComment({
        owner,
        repo,
        comment_id: commentId,
      });
      return response.data.map((r) => r.content);
    }
  } catch {
    return [];
  }
}

async function getPrFeedback(prNumber: number, markAsSeen: boolean) {
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
          # 2. Reviews (Summaries + Inline Comments)
          reviews(last: 50) {
            nodes {
              author { login }
              body # The summary text
              state
              submittedAt
              # The inline code comments nested inside this review
              comments(last: 50) {
                nodes {
                  id
                  databaseId
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
    const content = await getFileContentAtCommit(octokit, owner, repo, headCommitSha, path);
    fileContentCache.set(path, content);
    return content;
  }

  // 2. Flatten Reviews and their nested Inline Comments
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

    // Add the Inline Comments associated with this review (these are review comments, reply via pulls API)
    if (review.comments.nodes.length > 0) {
      for (const comment of review.comments.nodes) {
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
            referencedCode = extractLines(fileContent, actualStartLine, endLine).replace(/[\t\n]/g, ' ');
          }
        }

        reviewData.push({
          type: `Inline Code`,
          commentType: "review" as const,
          commentId: comment.databaseId,
          user: review.author.login,
          body: comment.body,
          path: comment.path,
          line: isMultiLine ? undefined : endLine,
          lineRange: isMultiLine ? { start: startLine, end: endLine } : undefined,
          referencedCode,
          date: comment.createdAt,
          url: comment.url,
        });
      }
    }
  }

  // 3. Combine, Filter, and Sort
  const allInteraction = [...generalComments, ...reviewData]
    .filter((item) => item.user !== "coderabbitai") // <--- The Filter
    .sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime());

  // 4. Mark comments as seen (add eyes emoji) if requested
  if (markAsSeen) {
    for (const item of allInteraction) {
      if (item.commentId && item.commentType) {
        const reactions = await getCommentReactions(
          octokit,
          owner,
          repo,
          item.commentId,
          item.commentType,
        );
        // Only add eyes if we haven't reacted yet
        if (!reactions.includes("eyes") && !reactions.includes("+1")) {
          await reactToComment(
            octokit,
            owner,
            repo,
            item.commentId,
            item.commentType,
            "eyes",
          );
        }
      }
    }
  }

  // 5. Output
  console.log(JSON.stringify(allInteraction, null, 2));
}

async function markCommentAsDone(
  prNumber: number,
  commentId: number,
  commentType: "review" | "issue",
) {
  const authToken = await getAuthToken();
  const octokit = new Octokit({ auth: authToken });
  const { owner, repo } = await getRepoInfo();

  await reactToComment(octokit, owner, repo, commentId, commentType, "+1");
  console.log(JSON.stringify({ success: true, commentId, reaction: "+1" }, null, 2));
}

yargs(hideBin(process.argv))
  .scriptName("agh")
  .usage("$0 <command> [options]")
  .command(
    "get-pr-feedback",
    "Get feedback comments from a pull request (infers PR from current branch)",
    (yargs) => {
      return yargs.option("mark-as-seen", {
        alias: "s",
        type: "boolean",
        description: "Add eyes emoji to comments that haven't been seen yet",
        default: false,
      });
    },
    async (argv) => {
      const prNumber = await getCurrentPrNumber();
      await getPrFeedback(prNumber, argv["mark-as-seen"]);
    },
  )
  .command(
    "mark-done",
    "Mark a comment as done with a thumbs up reaction",
    (yargs) => {
      return yargs
        .option("comment-id", {
          alias: "c",
          type: "number",
          description: "The comment ID to mark as done (from get-pr-feedback output)",
          demandOption: true,
        })
        .option("type", {
          alias: "t",
          type: "string",
          choices: ["review", "issue"] as const,
          description: "The type of comment: 'review' for inline code comments, 'issue' for general comments",
          demandOption: true,
        });
    },
    async (argv) => {
      const prNumber = await getCurrentPrNumber();
      await markCommentAsDone(
        prNumber,
        argv["comment-id"],
        argv.type as "review" | "issue",
      );
    },
  )
  .demandCommand(1, "You need to specify a command")
  .help()
  .parseAsync();
