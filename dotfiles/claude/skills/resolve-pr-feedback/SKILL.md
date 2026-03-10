---
name: resolve-pr-feedback
description: Use when the user wants to resolve, address, or fix PR review feedback, PR comments, or code review suggestions — fetches review comments from GitHub, triages into fix vs dismiss, applies fixes in parallel worktrees with batched review
---

# Resolve PR Feedback

Fetch all unresolved review feedback on a pull request, triage items into fix vs dismiss, then apply fixes and resolve threads.

Uses the `agh` CLI tool for all GitHub interactions.

---

## Phase 1: Fetch Review Comments

1. Run `agh get-pr-feedback` (infers PR from current branch via `gh pr view`):
   ```bash
   agh get-pr-feedback
   ```

   If the current branch has no PR, `agh` will error. Use **AskUserQuestion** to ask the user which branch to check out, or have them provide a PR number.

2. The output is a JSON array of feedback items. Each item has:
   - `type` — `"General Comment"`, `"Review (CHANGES_REQUESTED)"`, `"Review (COMMENTED)"`, or `"Inline Code"`
   - `commentType` — `"review"` (inline code comments), `"issue"` (general comments), or `null` (review summaries)
   - `commentId` — numeric comment ID (for replying). Null for review summaries.
   - `threadId` — GraphQL node ID of the review thread (for resolving). Only present on `"Inline Code"` items.
   - `user` — who left the feedback
   - `body` — the comment text
   - `path` — file path (inline code comments only)
   - `line` / `lineRange` — line number or `{start, end}` range (inline code comments only)
   - `referencedCode` — the code snippet the comment refers to (inline code comments only)
   - `date` — ISO timestamp
   - `url` — link to the comment

3. `agh` already filters out resolved threads and most CodeRabbit bot comments. No additional filtering needed unless you see non-actionable items.

4. If no feedback items remain, report **"No unresolved feedback found"** and stop.

---

## Phase 2: Triage

1. Read each feedback item and categorize it into one of two buckets:

   **Likely Real Issues** (will fix):
   - Bug reports, logic errors, missing edge cases
   - Style/naming suggestions that improve clarity
   - Requests to add tests, error handling, or documentation
   - Actionable code suggestions (suggestion blocks, "consider doing X")
   - Security or performance concerns

   **Likely Junk** (will dismiss and resolve):
   - Nitpicks that are purely subjective with no clear improvement
   - Questions that were already answered in a later comment
   - Outdated feedback that no longer applies to current code
   - "Looks good" / acknowledgment comments with no action needed
   - Comments that are just discussion, not requesting changes

2. Present the triage to the user as a numbered list per category:

   ```
   ## Likely Real Issues (fix)
   1. @alice — src/handler.go:42 — missing nil check on user input
   2. @bob — internal/db/query.go:118 — SQL injection risk in dynamic query
   3. @alice — (PR comment) — add integration test for the new endpoint

   ## Likely Junk (dismiss)
   4. @bob — src/handler.go:10 — "maybe rename this variable?" (subjective)
   5. @carol — (review) — "LGTM" (no action needed)
   ```

3. Use **AskUserQuestion** to let the user confirm or reclassify:
   - Prompt: `"Confirm triage or reclassify (e.g., 'fix 4 — junk 2' or 'looks good'):"`
   - Parse the response:
     - `"looks good"` or `"ok"` or `"confirm"` — proceed as-is
     - `"fix N"` — move item N from junk to fix
     - `"junk N"` — move item N from fix to junk
     - Combined: `"fix 4 — junk 2"` — apply both reclassifications
   - After reclassification, do NOT re-prompt. Proceed to the next phase.

---

## Phase 3: Dismiss Junk Items

1. Process all junk items **in parallel**. For each junk item:

   a. **Reply** using `agh reply-to-comment`:
      ```bash
      agh reply-to-comment --comment-id COMMENT_ID --type COMMENT_TYPE --body "dismissal message"
      ```
      - `--comment-id`: the item's `commentId`
      - `--type`: the item's `commentType` (`"review"` or `"issue"`)
      - `--body`: a brief, context-appropriate dismissal tailored to the specific comment. Do NOT use generic responses. Examples:
        - "Not applicable to this codebase's conventions."
        - "Intentional — [brief reason]."
        - "Acknowledged, but not addressing in this PR."

   b. **Resolve the thread** (for items with a `threadId`) using `agh resolve-thread`:
      ```bash
      agh resolve-thread --thread-id THREAD_ID
      ```
      If no `threadId` is available for an item (general PR comments, review summaries), skip the resolve step and just reply.

2. Items with `commentType: null` (review summaries) cannot be replied to — skip them entirely.

---

## Phase 4: Fix Items in Parallel Worktrees

1. **Group fix items by file path.** Items touching the same file go in the same group. If a feedback item doesn't reference a specific file, put it in its own group.

2. **Dispatch a subagent** for each group using the Agent tool with `isolation: "worktree"`.

   Subagent prompt template:
   ```
   You are resolving PR feedback on the following file(s). For each feedback item, make the fix and create a commit.

   Branch: {pr_branch}

   Feedback items to fix:

   ## Item {N}: {path}:{line}
   **Reviewer:** {user}
   **Comment:** {body}
   **Referenced code:** {referencedCode}

   Fix this issue. Create a commit with message:
   "fix: {one-line summary of fix} (PR feedback #{item_number})"

   IMPORTANT:
   - Read the file(s) before making changes
   - One commit per feedback item
   - Keep fixes minimal — only change what the feedback asks for
   - Do not refactor surrounding code
   ```

3. Run **all group subagents in parallel** (multiple Agent tool calls in a single message). Wait for all to complete before proceeding to Phase 5.

---

## Phase 5: Batched Review

1. Present each fix to the user **one at a time**:

   ```
   ### Fix {N}/{total}: {path}:{line}

   **Original feedback** (@{user}):
   > {comment body}

   **Diff:**
   {git diff for this commit — use: git -C {worktree_path} show {commit_sha} --stat --patch}

   **approve** / **drop** / **redo** (with guidance)?
   ```

2. Use **AskUserQuestion** for each fix. Parse the response:
   - **approve** (or `"y"`, `"yes"`, `"ok"`, `""`): Mark as approved.
   - **drop**: Mark as dropped — do not apply this commit.
   - **redo [guidance]**: Resume the subagent for that worktree with the user's guidance. The subagent should revert its commit, re-read the feedback, apply the guidance, and create a new commit.

3. After all fixes are reviewed, collect any redo items and run another review pass. Repeat until no more redos remain.

---

## Phase 6: Apply Approved Fixes & Cleanup

1. **Cherry-pick approved commits** onto the PR branch. For each approved commit, in the order they were reviewed:
   ```bash
   git cherry-pick {commit_sha}
   ```

2. **Handle cherry-pick conflicts.** If a cherry-pick conflict occurs:
   1. Show the conflict to the user with `git diff`
   2. Analyze the conflict and suggest a resolution
   3. Use **AskUserQuestion** to ask the user for approval before applying the resolution
   4. If approved, resolve and continue:
      ```bash
      git add . && git cherry-pick --continue
      ```
   5. If rejected, skip this commit:
      ```bash
      git cherry-pick --abort
      ```

3. **Clean up worktrees.** After all cherry-picks are applied (or skipped), remove all worktrees:
   - Worktrees with no remaining changes are cleaned up automatically by the Agent tool with `isolation: "worktree"`.
   - For worktrees with unapplied commits (dropped items), clean up manually:
     ```bash
     git worktree remove {worktree_path} --force
     ```

4. **Reply to fixed items** on GitHub. For each approved fix, reply to the original comment acknowledging the fix:
   ```bash
   agh reply-to-comment --comment-id COMMENT_ID --type COMMENT_TYPE --body "Fixed in {commit_sha_short}."
   ```
   Then resolve the thread if it has a `threadId`:
   ```bash
   agh resolve-thread --thread-id THREAD_ID
   ```

5. **Present a final summary** to the user:

   ```
   ## PR Feedback Resolution Complete

   **Fixed:** {N} items applied to branch
   **Dismissed:** {N} junk items replied + resolved
   **Dropped:** {N} items skipped
   **Failed:** {N} items (if any)

   Push changes? (y/n)
   ```

6. Use **AskUserQuestion** to ask whether to push. If the user says yes, push the branch:
   ```bash
   git push
   ```

---

## Edge Cases

- **No open PR for current branch** — `agh` will error. Ask the user to check out the PR branch or provide a PR number.
- **No unresolved feedback** — Report "No unresolved feedback found" and exit.
- **Review comments vs PR comments** — Review comments have threads (can be resolved via `threadId`). General PR comments do not. Only attempt to resolve review comment threads.
- **Review summaries** — Items with `commentType: null` cannot be replied to or resolved. Use them as context only.
- **Large bot comments** — `agh` filters CodeRabbit bot comments except for inline review comments that may contain actionable suggestions. Review these during triage.

---

## Common Mistakes

- Don't resolve threads for general PR comments — only items with a `threadId` can be resolved.
- Don't use a generic dismissal for all junk items — tailor each reply to the specific comment.
- Don't commit in the main worktree during the fix phase — all fixes happen in isolated worktrees.
- Don't cherry-pick dropped commits — only apply approved ones.
- Don't forget to reply + resolve fixed items after cherry-picking (Phase 6 step 4).
