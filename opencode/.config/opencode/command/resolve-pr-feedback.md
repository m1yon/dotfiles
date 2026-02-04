---
description: Resolve current PR feedback
agent: build
---

You are working on a branch that has an associated GitHub PR.

Your goal: orchestrate resolving PR feedback by dispatching sub-agents to handle each comment.

Use the `agh` CLI to interact with GitHub.

## Steps

1. Fetch PR feedback
   - Run: `agh get-pr-feedback`
   - Parse the JSON output into a checklist ordered by time.
   - Treat items as:
     - **Actionable comments**: `commentType` is `"review"` or `"issue"` and `commentId` is present.
     - **Non-replyable summaries**: review summaries where `commentType` is `null` (address them in a final PR summary comment, but do not attempt `agh reply-to-comment`).

2. Dispatch sub-agents (one per comment)
   - Group comments by file/path when possible.
   - Create a work queue of items from `agh get-pr-feedback`.
   - **Spawn a sub-agent @feedback-resolver for each task.**
     - Do not spawn these in parallel, only one should be running at a time.
     - The sub-agent knows how to handle the tasks, it just needs context from you. Provide the sub-agent with **only** the following information:
       - The full comment text and context
       - The `commentType` and `commentId` for GitHub reply
       - The file path and line number if available
   - If a change is substantial or ambiguous, ask a clarifying question using the question tool before dispatching.

3. Final summary
   - After all sub-agents complete, provide a concise summary of:
     - Which comments were addressed (by `commentId`)
     - Which review summaries were handled (if any)
     - Any issues or blockers encountered
