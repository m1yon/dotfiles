---
name: resolve-pr-feedback
description: Use when the user wants to resolve, address, or fix PR review feedback, PR comments, or code review suggestions — fetches review comments from GitHub, triages into fix vs dismiss, applies fixes in parallel worktrees with interactive staged review
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

5. **Record the current branch, HEAD, and main worktree path** for use throughout the workflow:
   ```bash
   MAIN_WORKTREE=$(git rev-parse --show-toplevel)
   PR_BRANCH=$(git symbolic-ref --short HEAD)
   PR_HEAD=$(git rev-parse HEAD)
   ```
   Store these values — they are needed in Phase 4 (worktree setup) and Phase 5 (pre-cherry-pick validation). Use `MAIN_WORKTREE` with `git -C` for all Phase 5 commands to ensure they run in the correct directory.

6. **Clean up stale worktrees** from previous runs:
   ```bash
   git worktree prune
   ```
   Also remove any leftover `worktree-agent-*` branches:
   ```bash
   git branch --list 'worktree-agent-*' | xargs -r git branch -D
   ```

---

## Phase 2: Triage

1. Read each feedback item and assign a severity level:

   | Emoji | Severity | Examples |
   |-------|----------|----------|
   | 🔴 | **Critical** | Security vulnerabilities, data loss, crashes, SQL injection |
   | 🟠 | **Important** | Bug reports, logic errors, missing edge cases |
   | 🟡 | **Moderate** | Style/naming improvements, missing tests, error handling |
   | 🟢 | **Low** | Nitpicks, formatting, minor suggestions |
   | ⚪ | **Info** | "LGTM", acknowledgments, discussion, already-answered questions |

2. Present ALL feedback items in a single numbered list, sorted by severity (critical first). Each item should include enough context for the user to decide whether it's worth fixing — include the reviewer's comment (quoted or summarized) and the referenced code if available:

   ```
   ## PR Feedback (5 items — all will be fixed unless you exclude some)

   1. 🔴 @bob — internal/db/query.go:118 — SQL injection risk in dynamic query
      > "The query string is built with fmt.Sprintf using user input directly — this is injectable."
      Code: `db.Query(fmt.Sprintf("SELECT * FROM users WHERE name = '%s'", name))`

   2. 🟠 @alice — src/handler.go:42 — missing nil check on user input
      > "req.Body could be nil here, this will panic on POST requests with no body."
      Code: `json.NewDecoder(req.Body).Decode(&input)`

   3. 🟡 @alice — (PR comment) — add integration test for the new endpoint
      > "Can we add a test that hits /api/tasks with auth headers to cover the happy path?"

   4. 🟢 @bob — src/handler.go:10 — suggests using custom error type
      > "Minor: could use a typed error here instead of fmt.Errorf for better downstream handling."
      Code: `return fmt.Errorf("invalid input: %s", msg)`

   5. ⚪ @carol — (review) — "LGTM"
   ```

3. Use **AskUserQuestion** to let the user choose which items to skip:
   - Prompt: `"All items will be fixed by default. Enter numbers to ignore (e.g., '4 5'), or press enter to fix all:"`
   - Parse the response:
     - Empty / `"ok"` / `"all"` — fix all items
     - Space-separated numbers (e.g., `"4 5"`) — ignore those items (dismiss + resolve)
   - After selection, do NOT re-prompt. Proceed to the next phase.
   - Items the user chooses to ignore are treated as **dismissed** (Phase 3). All remaining items are treated as **fixes** (Phase 4).

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

   CRITICAL — Branch setup:
   The worktree may not be on the correct branch. Before doing anything else, run:
     git checkout {pr_branch}
   Then verify you are at the expected commit:
     git rev-parse HEAD
   Expected HEAD: {pr_head}
   If HEAD does not match, STOP and report the mismatch. Do NOT proceed with fixes on the wrong base.

   Feedback items to fix:

   ## Item {N}: {path}:{line}
   **Reviewer:** {user}
   **Comment:** {body}
   **Referenced code:** {referencedCode}

   Fix this issue. Create a commit with message:
   "fix: {one-line summary of fix} (PR feedback #{item_number})"

   IMPORTANT:
   - Read the file(s) before making changes — verify the file content matches the referenced code
   - If the file content does not match the referenced code, STOP and report the mismatch
   - One commit per feedback item
   - Keep fixes minimal — only change what the feedback asks for
   - Do not refactor surrounding code
   ```

3. Run **all group subagents in parallel** (multiple Agent tool calls in a single message). Wait for all to complete before proceeding to Phase 5.

---

## Phase 5: Interactive Staged Review

1. Present each fix to the user **one at a time**. For each fix:

   a. **Announce the fix:**
      ```
      ### Fix {N}/{total}: {path}:{line}

      **Original feedback** (@{user}):
      > {comment body}
      ```

   b. **Verify HEAD before cherry-picking.** Use `git -C {MAIN_WORKTREE}` to ensure commands run in the main worktree regardless of shell working directory:
      ```bash
      git -C {MAIN_WORKTREE} symbolic-ref --short HEAD  # must match {pr_branch}
      git -C {MAIN_WORKTREE} rev-parse HEAD              # must match expected commit
      ```
      If HEAD has been displaced (e.g., onto a `worktree-agent-*` branch), recover with `git -C {MAIN_WORKTREE} checkout {pr_branch}` before proceeding.

   c. **Cherry-pick without committing:**
      ```bash
      git -C {MAIN_WORKTREE} cherry-pick --no-commit {commit_sha}
      ```
      This stages all changes from the fix without creating a commit.

   d. **Handle conflicts.** If the cherry-pick produces conflicts:
      1. Analyze the conflicts and resolve them.
      2. Stage the resolution with `git add`.
      3. Inform the user: "Cherry-pick had conflicts — I resolved them. Run `git diff --staged` to review the full result including my conflict resolution."

   e. **Prompt review:**
      Tell the user: "Changes are staged. Run `git diff --staged` to review."

   f. **AskUserQuestion** with context — show the original feedback and a brief summary of what the fix does, then ask for approval:
      ```
      **Original feedback** (@{user}): {comment body}
      **Fix summary:** {1-sentence description of what the fix changed}

      approve (enter) / drop / or type feedback to redo:
      ```

   g. **Act on response** (all commands use `git -C {MAIN_WORKTREE}`):
      - **approve** (or `"y"`, `"yes"`, `"ok"`, `""`): Commit the staged changes:
        ```bash
        git -C {MAIN_WORKTREE} commit -m "fix: {one-line summary} (PR feedback #{item_number})"
        ```
      - **drop**: Discard the staged changes:
        ```bash
        git -C {MAIN_WORKTREE} reset && git -C {MAIN_WORKTREE} checkout -- . && git -C {MAIN_WORKTREE} clean -fd
        ```
      - **anything else** (redo): Treat the entire response as guidance. Discard the staged changes (`git -C {MAIN_WORKTREE} reset && git -C {MAIN_WORKTREE} checkout -- . && git -C {MAIN_WORKTREE} clean -fd`), resume the subagent for that worktree with the user's guidance. The subagent should revert its commit, re-read the feedback, apply the guidance, and create a new commit. Then re-apply via `cherry-pick --no-commit` and repeat from step (d).

2. After all fixes are reviewed, collect any redo items and run another review pass. Repeat until no more redos remain.

---

## Phase 6: Cleanup & Resolve

1. **Clean up worktrees.** After all fixes are reviewed and committed (or dropped), remove all worktrees:
   - Worktrees with no remaining changes are cleaned up automatically by the Agent tool with `isolation: "worktree"`.
   - For worktrees with unapplied commits (dropped items), clean up manually:
     ```bash
     git worktree remove {worktree_path} --force
     ```

2. **Reply to fixed items** on GitHub. For each approved fix, reply to the original comment acknowledging the fix:
   ```bash
   agh reply-to-comment --comment-id COMMENT_ID --type COMMENT_TYPE --body "Fixed in {commit_sha_short}."
   ```
   Then resolve the thread if it has a `threadId`:
   ```bash
   agh resolve-thread --thread-id THREAD_ID
   ```

3. **Present a final summary** to the user:

   ```
   ## PR Feedback Resolution Complete

   **Fixed:** {N} items applied to branch
   **Dismissed:** {N} junk items replied + resolved
   **Dropped:** {N} items skipped
   **Failed:** {N} items (if any)

   Push changes? (y/n)
   ```

4. Use **AskUserQuestion** to ask whether to push. If the user says yes, push the branch:
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
- Don't show diffs inline during review — let the user review with `git diff --staged`.
- Don't forget to discard staged changes for dropped items — use `git reset && git checkout -- . && git clean -fd`.
- Don't forget to reply + resolve fixed items after committing (Phase 6 step 2).
- Don't trust `isolation: "worktree"` to use the current branch — it may default to the repo's default branch. Always explicitly checkout `{pr_branch}` in the worktree agent and verify HEAD matches `{pr_head}`.
- Don't skip stale worktree cleanup — leftover `worktree-agent-*` branches from previous runs can cause branch lock conflicts and confusing state.
- Don't cherry-pick without first verifying `git symbolic-ref --short HEAD` matches the PR branch — a failed cherry-pick or reset can displace HEAD onto a worktree branch.
- Don't `cd` into worktree directories to inspect commits or logs — use `git -C <worktree_path> log` instead. The shell working directory persists across Bash tool calls, and subsequent git commands (cherry-pick, checkout, reset) will silently run in the worktree instead of the main worktree. Always use `git -C {MAIN_WORKTREE}` for Phase 5 commands.
