---
description: Resolve current PR feedback
agent: build
model: opencode/claude-opus-4-5
---

You are working on a branch that has an associated GitHub PR.

Your goal: fully resolve PR feedback by (1) collecting all non-bot PR comments via `agh`, (2) making targeted code changes, (3) running lint/format/tests, and (4) replying back on GitHub to each actionable comment.

Use the `agh` CLI to interact with GitHub.

## Steps

1. Fetch PR feedback
   - Run: `agh get-pr-feedback`
   - Parse the JSON output into a checklist ordered by time.
   - Treat items as:
     - **Actionable comments**: `commentType` is `"review"` or `"issue"` and `commentId` is present.
     - **Non-replyable summaries**: review summaries where `commentType` is `null` (address them in a final PR summary comment, but do not attempt `agh reply-to-comment`).

2. Triage and dispatch sub-agents (one per comment)
   - Group comments by file/path when possible.
   - Create a work queue of items from `agh get-pr-feedback`.
   - **IMPORTANT Spawn a sub-agent @software-engineer for each task to implement the fix.**
      - Do not spawn these in parallel, only one should be running at a time.
      - These are dumb agents. Give them an exact plan with the implementation code if you can.
      - Tell them to verify their changes (see 4).
      - After each agent is done, verify their work and commit, push, and reply on GitHub (see 5).
   - If a change is substantial or ambiguous, you should ask a clarifying question using the question tool before coding.

3. Apply fixes
   - Integrate each sub-agent's patch into the branch.
   - Keep changes narrowly scoped to the feedback; avoid refactors unless requested.
   - **Create a separate commit for each fix and immediately push** with a clear commit message describing the change.

4. Run verification (format/lint/tests) — must pass before replying
   - Detect the repo’s standard commands (e.g., `make`, `task`, `npm/pnpm/yarn`, `go test`, `pytest`, etc.).
   - Run formatter (if configured), linter (if configured), and the relevant test suite.
   - If anything fails, fix only issues caused by your changes or required by the feedback.
   - Repeat verification until it passes (or stop and report blockers).

5. Reply on GitHub (auto-post, after verification passes)
   - Only after step 4 passes, post the prepared replies.
   - For each actionable item (has `commentType` + `commentId`), post a reply using:
     - `agh reply-to-comment -t <review|issue> -c <commentId> -b "<reply>"`
   - Each reply should be in the following format: **Include "fixed in <commit-sha>"** where `<commit-sha>` is the short SHA of the commit that addressed the feedback
   - Do not claim the PR is fixed on GitHub until the fix is actually present in the PR branch.

6. Final summary
   - Provide a concise summary of:
     - Which comments were addressed (by `commentId`)
     - Which review summaries were handled (if any)
     - Commands run and results
