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

async function getPrFeedback(prNumber: number) {
  const authToken = await getAuthToken();
  const octokit = new Octokit({ auth: authToken });
  const { owner, repo } = await getRepoInfo();

  const query = `
    query($owner: String!, $name: String!, $number: Int!) {
      repository(owner: $owner, name: $name) {
        pullRequest(number: $number) {
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

  // 2. Flatten Reviews and their nested Inline Comments
  const reviewData = pr.reviews.nodes.flatMap((review: any) => {
    const items = [];

    // Add the Review Summary (if it has text) - these cannot be replied to directly
    if (review.body && review.body !== "") {
      items.push({
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
      review.comments.nodes.forEach((comment: any) => {
        // Determine line range for the comment
        // GitHub uses 'line' for single-line comments, 'startLine' and 'line' for multi-line
        const endLine = comment.line || comment.originalLine;
        const startLine = comment.startLine || comment.originalStartLine || endLine;
        const isMultiLine = startLine && endLine && startLine !== endLine;

        items.push({
          type: `Inline Code`,
          commentType: "review" as const,
          commentId: comment.databaseId,
          user: review.author.login,
          body: comment.body,
          path: comment.path,
          line: isMultiLine ? undefined : endLine,
          lineRange: isMultiLine ? { start: startLine, end: endLine } : undefined,
          date: comment.createdAt,
          url: comment.url,
        });
      });
    }

    return items;
  });

  // 3. Combine, Filter, and Sort
  const allInteraction = [...generalComments, ...reviewData]
    .filter((item) => item.user !== "coderabbitai") // <--- The Filter
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
    console.log(JSON.stringify({
      success: true,
      url: response.data.html_url,
      id: response.data.id,
    }, null, 2));
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
    console.log(JSON.stringify({
      success: true,
      url: response.data.html_url,
      id: response.data.id,
    }, null, 2));
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
          description: "The comment ID to reply to (from get-pr-feedback output)",
          demandOption: true,
        })
        .option("type", {
          alias: "t",
          type: "string",
          choices: ["review", "issue"] as const,
          description: "The type of comment: 'review' for inline code comments, 'issue' for general comments",
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
