---
name: pr-feedback-to-issues
description: Convert PR review feedback into Linear sub-issues under a parent PRD issue. Fetches unresolved comments via agh CLI, auto-filters noise, groups by logical concern, then grills the user on each group to validate feedback and gather requirements before creating issues. Use when user wants to turn PR feedback into issues, create issues from review comments, or track PR feedback as issues.
allowed-tools:
  - Bash(agh:*)
  - Bash(gh:*)
  - Bash(git:*)
---

# PR Feedback to Issues

Convert unresolved PR review feedback into Linear sub-issues under a parent PRD issue. Each group of feedback is interrogated with the user to validate it and gather requirements before any issue is created.

---

## Phase 1: Fetch PR & Load PRD

1. Get the current PR number and repo:
   ```bash
   gh pr view --json number,url,title,headRefName,body --jq '{number, url, title, branch: .headRefName, body}'
   ```
   If no PR exists for the current branch, stop and inform the user.

2. **Extract the PRD issue from the PR title.** The PR title contains the parent Linear issue identifier (e.g., `MECA-123`). Extract it and use the `get_issue` MCP tool to fetch the full issue — this is the PRD and also the parent issue for any sub-issues created later. Keep the PRD in context for the rest of the skill so you can reference it during the grill phase (e.g., to check whether feedback aligns with requirements, is out of scope, or contradicts the design).

   If no identifier is found in the title, fall back to the PR body, then the branch name. If still not found, ask the user.

3. Fetch unresolved feedback:
   ```bash
   agh get-pr-feedback
   ```
   Output is a JSON array. Each item has: `type`, `commentType` (`"review"`, `"issue"`, or `null`), `commentId`, `threadId`, `user`, `body`, `path`, `line`, `lineRange`, `referencedCode`, `date`, `url`.

4. If no feedback items, report "No unresolved feedback found" and stop.

---

## Phase 2: Auto-Filter

Fetch the parent issue's sub-issues via `get_issue` MCP tool. Filter to those with the **Feedback** label — these are previously created feedback issues.

Remove items that don't need processing. Drop any item where:
- The body is purely an acknowledgment ("LGTM", "Looks good", "Thanks", "+1", thumbs up, etc.)
- `commentType` is `null` AND the body contains no concrete ask or suggestion (review summaries that are just approval)
- The body is only a question with no implied change request
- The feedback is already tracked by an existing **Feedback**-labeled sub-issue (match by comment URL in the issue body or substantially similar content)

Keep items that contain a concrete suggestion, bug report, request for change, or actionable feedback — even if phrased as a question (e.g., "Should this handle nil?").

If all items are filtered out, report "No actionable feedback found" and stop.

---

## Phase 3: Group by Concern

Analyze the remaining items and group them by logical task — the way a developer would tackle them together:
- Comments about the same concern across files go together (e.g., "missing error handling" in 3 places)
- Unrelated comments on the same file stay separate (e.g., security fix vs typo)
- Each group should be a coherent unit of work

---

## Phase 4: Process Each Group

Loop through each group one at a time, completing the full cycle — grill, then act — before moving to the next group.

### For each group:

#### 4a: Present

Show the user:
- A proposed title summarizing the concern
- The feedback comments (quoted, with file/line references)
- The referenced code snippets

#### 4b: Validate

Give your recommendation on whether this is valid feedback worth fixing (referencing the PRD and codebase as needed), then ask the user to confirm. If the user says no, skip to dismissal in 4d. If yes, proceed to 4c.

#### 4c: Grill — Gather Requirements (if valid)

Interview the user about the requirements for this issue until reaching shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one. Ask questions **one at a time**, giving your recommended answer for each.

Focus on business logic and interfaces, not implementation details. If a question can be answered by exploring the codebase or referencing the PRD, do that instead of asking the user.

#### 4d: Act — Create Issue or Dismiss

After the interview, immediately act on the outcome:

**If creating an issue:**

1. Create a Linear sub-issue using the `save_issue` MCP tool on the **MECA Therapies** team:
   - Set the **parent issue** to the PRD issue from Phase 1.
   - Set the issue type to **Bug** if the feedback describes a defect, otherwise **Feature**.
   - Assign the issue to me.
   - Apply the **AI** and **Feedback** labels.
   - **Title:** A concise description of the concern (synthesized, not the reviewer's words verbatim).
   - **Body:**
     ```markdown
     [View PR feedback]({url of first comment in group})

     Relates to PR #{pr_number}

     ## Requirements

     {Acceptance criteria and requirements gathered during the grill phase}

     ## Feedback

     {For each comment in the group:}

     ### {path}:{line} (@{user})

     > {quoted comment body}

     ```{language}
     {referencedCode}
     ```

     [View comment]({url})

     {End for each}
     ```
2. Reply on the PR for each comment in the group:
   ```bash
   agh reply-to-comment --comment-id COMMENT_ID --type COMMENT_TYPE --body "Tracked in MECA-123"
   ```
   - Skip items with `commentType: null`.

**If dismissing:**

1. Reply to each comment in the group with a concise, respectful explanation:
   ```bash
   agh reply-to-comment --comment-id COMMENT_ID --type COMMENT_TYPE --body "DISMISSAL_REASON"
   ```
   - Skip items with `commentType: null`.
2. Resolve each thread:
   ```bash
   agh resolve-thread --thread-id THREAD_ID
   ```
   - Skip items without a `threadId`.

Then move to the next group.

---

## Phase 5: Summary

Print a summary:
```
## PR Feedback Issues Created

**Parent issue:** MECA-XXX
**Created:** {N} issues from {M} feedback items
**Dismissed:** {N} items (with reasons replied on PR)
**Skipped (noise):** {N} non-actionable items
**Skipped (duplicate):** {N} already-tracked items

Issues:
- MECA-123: {title}
- MECA-124: {title}

Dismissed:
- {group title}: {one-line reason}
```

---

## Common Mistakes

- Don't create issues without grilling first — every group must go through Phase 4.
- Don't ask the user questions you can answer by reading the codebase.
- Don't create issues for non-actionable feedback — auto-filter must run first.
- Don't group by file — group by logical concern/theme.
- Don't create duplicate issues — auto-filter checks existing Feedback-labeled sub-issues.
- Don't reply to items with `commentType: null` — review summaries have no comment endpoint.
- Don't forget the PR reference ("Relates to PR #N") in the issue body.
- Don't forget to resolve threads when dismissing feedback.
