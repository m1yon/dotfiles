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
    throw new Error("Failed to get auth token. Are you logged in with `gh auth login`?");
  }

  return output.trim();
}

const argv = await yargs(hideBin(process.argv))
  .option("pr", {
    alias: "p",
    type: "number",
    description: "Pull request number",
    demandOption: true,
  })
  .help()
  .parseAsync();

const authToken = await getAuthToken();
const octokit = new Octokit({ auth: authToken });

const { owner: OWNER, repo: REPO } = await getRepoInfo();
const PR_NUMBER = argv.pr;

async function getPrComments() {
  const query = `
    query($owner: String!, $name: String!, $number: Int!) {
      repository(owner: $owner, name: $name) {
        pullRequest(number: $number) {
          # 1. General Timeline Comments
          comments(last: 100) {
            nodes {
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
                  body
                  path
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
    owner: OWNER,
    name: REPO,
    number: PR_NUMBER,
  });

  const pr = response.repository.pullRequest;

  // --- PROCESSING & FILTERING ---

  // 1. Flatten General Comments
  const generalComments = pr.comments.nodes.map((c: any) => ({
    type: "General Comment",
    user: c.author.login,
    body: c.body,
    date: c.createdAt,
    url: c.url,
  }));

  // 2. Flatten Reviews and their nested Inline Comments
  const reviewData = pr.reviews.nodes.flatMap((review: any) => {
    const items = [];

    // Add the Review Summary (if it has text)
    if (review.body && review.body !== "") {
      items.push({
        type: `Review (${review.state})`,
        user: review.author.login,
        body: review.body,
        date: review.submittedAt,
        url: null,
      });
    }

    // Add the Inline Comments associated with this review
    if (review.comments.nodes.length > 0) {
      review.comments.nodes.forEach((comment: any) => {
        items.push({
          type: `Inline Code (${comment.path})`,
          user: review.author.login,
          body: comment.body,
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
  console.log(allInteraction);
}

getPrComments();
