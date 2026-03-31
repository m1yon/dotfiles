---
name: pr-feedback-to-issues
description: Convert PR review feedback into Linear sub-issues under a parent PRD issue. Fetches unresolved comments via agh CLI, auto-filters noise, groups by logical concern, deduplicates against existing sub-issues, creates issues via Linear MCP, and replies on the PR with issue links. Use when user wants to turn PR feedback into issues, create issues from review comments, or track PR feedback as issues.
allowed-tools:
  - Bash(agh:*)
  - Bash(gh:*)
  - Bash(git:*)
---

# PR Feedback to Issues

Convert unresolved PR review feedback into Linear sub-issues under a parent PRD issue, grouped by logical concern, that an agent can pick up independently.

---

## Phase 1: Fetch & Identify PR

1. Get the current PR number and repo:
   ```bash
   gh pr view --json number,url,title,headRefName,body --jq '{number, url, title, branch: .headRefName, body}'
   ```
   If no PR exists for the current branch, stop and inform the user.

2. Fetch unresolved feedback:
   ```bash
   agh get-pr-feedback
   ```
   Output is a JSON array. Each item has: `type`, `commentType` (`"review"`, `"issue"`, or `null`), `commentId`, `threadId`, `user`, `body`, `path`, `line`, `lineRange`, `referencedCode`, `date`, `url`.

3. If no feedback items, report "No unresolved feedback found" and stop.

---

## Phase 2: Auto-Filter

Remove non-actionable items. Drop any item where:
- The body is purely an acknowledgment ("LGTM", "Looks good", "Thanks", "+1", thumbs up, etc.)
- `commentType` is `null` AND the body contains no concrete ask or suggestion (review summaries that are just approval)
- The body is only a question with no implied change request

Keep items that contain a concrete suggestion, bug report, request for change, or actionable feedback — even if phrased as a question (e.g., "Should this handle nil?").

If all items are filtered out, report "No actionable feedback found" and stop.

---

## Phase 3: Group by Concern

Analyze the remaining items and group them by logical task — the way a developer would tackle them together:
- Comments about the same concern across files go together (e.g., "missing error handling" in 3 places)
- Unrelated comments on the same file stay separate (e.g., security fix vs typo)
- Each group should be a coherent unit of work

---

## Phase 4: Infer Parent Linear Issue

The created issues will be sub-issues of a parent PRD Linear issue. Infer the parent issue identifier:

1. **Check PR description** — look for a Linear issue URL (e.g., `https://linear.app/meca-therapies/issue/MECA-123/...`) or identifier (e.g., `MECA-123`) in the PR body.
2. **Check branch name** — look for a Linear issue key in the branch name (e.g., `meca-123/some-feature` or `meca-123-some-feature`).
3. If a candidate is found, use the `get_issue` MCP tool to fetch it and confirm with the user: "I found parent issue MECA-123: [title]. Is this the correct parent issue?"
4. If no candidate is found, ask the user for the parent Linear issue identifier.

---

## Phase 5: Deduplicate

1. Use the `get_issue` MCP tool to fetch the parent issue's sub-issues (children).
2. For each group, check if a sub-issue with a substantially similar title already exists. If so, skip the group.

---

## Phase 6: Create Issues

For each non-duplicate group, create a Linear sub-issue using the `create_issue` MCP tool on the **MECA Therapies** team.

- Set the **parent issue** to the PRD issue from Phase 4.
- Set the issue type to **Bug** if the feedback describes a defect, otherwise **Feature**.
- Assign the issue to me.
- Apply the **AI** label.

**Title:** A concise description of the concern (not the reviewer's words verbatim — synthesize).

**Body format:**
```markdown
Relates to PR #{pr_number}

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

Capture the issue identifier from the response.

---

## Phase 7: Reply on PR

For each comment that was included in a created issue, reply on the PR:
```bash
agh reply-to-comment --comment-id COMMENT_ID --type COMMENT_TYPE --body "Tracked in MECA-123"
```

- Use the Linear issue identifier (e.g., `MECA-123`) in the reply body.
- Skip items with `commentType: null` (review summaries cannot be replied to).
- All comments in the same group get the same issue identifier.

---

## Phase 8: Summary

Print a summary:
```
## PR Feedback Issues Created

**Parent issue:** MECA-XXX
**Created:** {N} issues from {M} feedback items
**Skipped (noise):** {N} non-actionable items
**Skipped (duplicate):** {N} already-tracked items

Issues:
- MECA-123: {title}
- MECA-124: {title}
```

---

## Common Mistakes

- Don't create issues for non-actionable feedback — auto-filter must run first.
- Don't group by file — group by logical concern/theme.
- Don't create duplicate issues — always check existing sub-issues for similar titles.
- Don't reply to items with `commentType: null` — review summaries have no comment endpoint.
- Don't forget the PR reference ("Relates to PR #N") in the issue body.
